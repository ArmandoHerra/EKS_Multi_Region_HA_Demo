
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

# Primary failover record (East region)
resource "aws_route53_record" "primary" {
  count           = var.lb_hostname_east != "" ? 1 : 0
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = "${var.subdomain}.${var.domain_name}"
  type            = "CNAME"
  ttl             = 60
  records         = [var.lb_hostname_east]
  set_identifier  = "primary-east"
  health_check_id = aws_route53_health_check.east[0].id

  failover_routing_policy {
    type = "PRIMARY"
  }
}

# Secondary failover record (West region)
resource "aws_route53_record" "secondary" {
  count           = var.lb_hostname_west != "" ? 1 : 0
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = "${var.subdomain}.${var.domain_name}"
  type            = "CNAME"
  ttl             = 60
  records         = [var.lb_hostname_west]
  set_identifier  = "secondary-west"
  health_check_id = aws_route53_health_check.west[0].id

  failover_routing_policy {
    type = "SECONDARY"
  }
}