
# Primary repository in us-east-1
module "ecr_primary" {
  source          = "../../modules/ecr"
  repository_name = var.repository_name
  region_suffix   = "east"
  providers = {
    aws = aws
  }
}

# Secondary repository in us-west-2
module "ecr_secondary" {
  source          = "../../modules/ecr"
  repository_name = var.repository_name
  region_suffix   = "west"
  providers = {
    aws = aws.us_west
  }
}

# Set up cross-region replication from primary to secondary.
# This resource uses the primary provider.
resource "aws_ecr_replication_configuration" "replication" {
  replication_configuration {
    rule {
      # Replicate images to us-west-2.
      destination {
        region      = "us-west-2"
        registry_id = data.aws_caller_identity.current.account_id
      }

      # This rule applies to repositories with names that start with the given prefix.
      repository_filter {
        filter      = var.repository_name
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}

# Create an IAM policy that allows EKS worker nodes to pull images from a specific ECR repository.
resource "aws_iam_policy" "ecr_read" {
  name        = "${var.cluster_name}-ecr-read"
  description = "Allow EKS nodes to pull images from the specified ECR repository"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        Resource : var.ecr_repo_arn
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "eks_admin_attachment" {
  name       = "eks-admin-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  users      = [var.iam_username]
  lifecycle {
    ignore_changes = []
  }
}

module "eks_cluster_east" {
  source                  = "../../modules/eks"
  region                  = var.aws_region
  cluster_name            = "${var.cluster_name}-east"
  cluster_version         = var.cluster_version
  vpc_id                  = data.aws_vpc.default_east.id
  subnets                 = local.east_subnet_ids
  eks_managed_node_groups = var.eks_managed_node_groups
  ecr_policy_arn          = aws_iam_policy.ecr_read.arn
  tags                    = var.tags
}

module "eks_cluster_west" {
  source                  = "../../modules/eks"
  region                  = "us-west-2"
  cluster_name            = "${var.cluster_name}-west"
  cluster_version         = var.cluster_version
  vpc_id                  = data.aws_vpc.default_west.id
  subnets                 = local.west_subnet_ids
  eks_managed_node_groups = var.eks_managed_node_groups
  ecr_policy_arn          = aws_iam_policy.ecr_read.arn
  tags                    = var.tags
}

# =============================================================================
# Route53 Failover Configuration
# =============================================================================

# Look up existing hosted zone
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Health check for East region LoadBalancer
resource "aws_route53_health_check" "east" {
  count             = var.lb_hostname_east != "" ? 1 : 0
  fqdn              = var.lb_hostname_east
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-east-health-check"
  })
}

# Health check for West region LoadBalancer
resource "aws_route53_health_check" "west" {
  count             = var.lb_hostname_west != "" ? 1 : 0
  fqdn              = var.lb_hostname_west
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-west-health-check"
  })
}

# Weighted record (East region) - 50% traffic (only when cross-cloud failover is disabled)
resource "aws_route53_record" "primary" {
  count           = var.lb_hostname_east != "" && !var.enable_cross_cloud_failover ? 1 : 0
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = "${var.subdomain}.${var.domain_name}"
  type            = "CNAME"
  ttl             = 60
  records         = [var.lb_hostname_east]
  set_identifier  = "weighted-east"
  health_check_id = aws_route53_health_check.east[0].id

  weighted_routing_policy {
    weight = 50
  }
}

# Weighted record (West region) - 50% traffic
resource "aws_route53_record" "secondary" {
  count           = var.lb_hostname_west != "" && !var.enable_cross_cloud_failover ? 1 : 0
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = "${var.subdomain}.${var.domain_name}"
  type            = "CNAME"
  ttl             = 60
  records         = [var.lb_hostname_west]
  set_identifier  = "weighted-west"
  health_check_id = aws_route53_health_check.west[0].id

  weighted_routing_policy {
    weight = 50
  }
}

# =============================================================================
# Cross-Cloud Failover to Azure
# =============================================================================

# Calculated health check - AWS pool healthy if at least 1 region is up
resource "aws_route53_health_check" "aws_pool_calculated" {
  count                  = var.enable_cross_cloud_failover && var.lb_hostname_east != "" && var.lb_hostname_west != "" ? 1 : 0
  type                   = "CALCULATED"
  child_health_threshold = 1 # Healthy if at least 1 child is healthy
  child_healthchecks = [
    aws_route53_health_check.east[0].id,
    aws_route53_health_check.west[0].id
  ]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-aws-pool-calculated"
  })
}

# Health check for Azure East US
resource "aws_route53_health_check" "azure_east" {
  count             = var.azure_lb_ip_east != "" ? 1 : 0
  ip_address        = var.azure_lb_ip_east
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 10

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-azure-east-health-check"
  })
}

# Health check for Azure West US 2
resource "aws_route53_health_check" "azure_west" {
  count             = var.azure_lb_ip_west != "" ? 1 : 0
  ip_address        = var.azure_lb_ip_west
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 10

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-azure-west-health-check"
  })
}

# =============================================================================
# Failover Records with Full AWS Multi-Region Coverage
# =============================================================================
# Architecture: Nested routing policies
#   eks-demo.domain.com (failover)
#     ├── PRIMARY → aws-pool.eks-demo.domain.com (weighted: East 50%, West 50%)
#     └── SECONDARY → Azure IPs
#
# This ensures both AWS regions participate in normal traffic distribution,
# and failover to Azure only happens when BOTH AWS regions are down.
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Pool: Weighted routing between East and West regions
# -----------------------------------------------------------------------------

# AWS Pool - East region (50% weight)
resource "aws_route53_record" "aws_pool_east" {
  count          = var.enable_cross_cloud_failover && var.lb_hostname_east != "" ? 1 : 0
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = "${var.aws_pool_subdomain}.${var.subdomain}.${var.domain_name}"
  type           = "A"
  set_identifier = "aws-pool-east"

  alias {
    name                   = var.lb_hostname_east
    zone_id                = var.elb_zone_id_east
    evaluate_target_health = true
  }

  weighted_routing_policy {
    weight = var.aws_east_weight
  }
}

# AWS Pool - West region (50% weight)
resource "aws_route53_record" "aws_pool_west" {
  count          = var.enable_cross_cloud_failover && var.lb_hostname_west != "" ? 1 : 0
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = "${var.aws_pool_subdomain}.${var.subdomain}.${var.domain_name}"
  type           = "A"
  set_identifier = "aws-pool-west"

  alias {
    name                   = var.lb_hostname_west
    zone_id                = var.elb_zone_id_west
    evaluate_target_health = true
  }

  weighted_routing_policy {
    weight = var.aws_west_weight
  }
}

# -----------------------------------------------------------------------------
# Main Failover: AWS Pool (PRIMARY) → Azure (SECONDARY)
# -----------------------------------------------------------------------------

# PRIMARY: Alias to AWS weighted pool with calculated health check
resource "aws_route53_record" "failover_primary_aws" {
  count           = var.enable_cross_cloud_failover && var.lb_hostname_east != "" && var.lb_hostname_west != "" ? 1 : 0
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = "${var.subdomain}.${var.domain_name}"
  type            = "A"
  set_identifier  = "failover-primary-aws-pool"
  health_check_id = aws_route53_health_check.aws_pool_calculated[0].id

  alias {
    name                   = "${var.aws_pool_subdomain}.${var.subdomain}.${var.domain_name}"
    zone_id                = data.aws_route53_zone.main.zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }
}

# Calculated health check for Azure pool - healthy if at least 1 Azure region is up
resource "aws_route53_health_check" "azure_pool_calculated" {
  count                  = var.enable_cross_cloud_failover && var.azure_lb_ip_east != "" && var.azure_lb_ip_west != "" ? 1 : 0
  type                   = "CALCULATED"
  child_health_threshold = 1 # Healthy if at least 1 child is healthy
  child_healthchecks = [
    aws_route53_health_check.azure_east[0].id,
    aws_route53_health_check.azure_west[0].id
  ]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-azure-pool-calculated"
  })
}

# SECONDARY: Azure (failover routing) - both Azure IPs as multivalue
resource "aws_route53_record" "failover_secondary_azure" {
  count           = var.enable_cross_cloud_failover && var.azure_lb_ip_east != "" && var.azure_lb_ip_west != "" ? 1 : 0
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = "${var.subdomain}.${var.domain_name}"
  type            = "A"
  ttl             = 30
  records         = [var.azure_lb_ip_east, var.azure_lb_ip_west]
  set_identifier  = "failover-secondary-azure"
  health_check_id = aws_route53_health_check.azure_pool_calculated[0].id

  failover_routing_policy {
    type = "SECONDARY"
  }
}