variable "aws_region" {
  description = "The AWS region for the primary resources."
  type        = string
  default     = "us-east-1"
}

variable "remote_state_bucket" {
  type        = string
  description = "Remote State Bucket to fetch outputs from other stacks"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster-dev"
}

variable "cluster_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.34"
}

variable "availability_zones" {
  description = "List of availability zones for the EKS cluster"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "eks_managed_node_groups" {
  description = "Configuration for the node groups in the cluster"
  type        = any
  default = {
    eks_nodes = {
      desired_size    = 3
      max_size        = 6
      min_size        = 3
      instance_types  = ["t3.small"]
      key_name        = ""
      additional_tags = {}
    }
  }
}

variable "tags" {
  description = "Tags to apply to the EKS cluster and its resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "EKS MultiRegion Demo"
  }
}

variable "iam_user_arn" {
  description = "The IAM user ARN to be added to the aws-auth ConfigMap."
  type        = string
  default     = "arn:aws:iam::933673765333:user/iamadmin"
}

variable "iam_username" {
  description = "The username for the IAM user, used in the aws-auth ConfigMap."
  type        = string
  default     = "iamadmin"
}

variable "ecr_repo_arn" {
  description = "ARN of the ECR repository that worker nodes should have read access to"
  type        = string
  default     = "arn:aws:ecr:us-east-1:933673765333:repository/basic-demo-microservice-01"
}

# Route53 Failover Configuration
variable "domain_name" {
  description = "The root domain name for the hosted zone"
  type        = string
  default     = "armandoherra.games"
}

variable "subdomain" {
  description = "The subdomain for the failover record (e.g., 'multi-cloud' creates multi-cloud.domain.com)"
  type        = string
  default     = "multi-cloud"
}

variable "lb_hostname_east" {
  description = "LoadBalancer hostname for the east region (set after k8s service deployment)"
  type        = string
  default     = "aedebc80d72774185a37eaca71389ebf-844492847.us-east-1.elb.amazonaws.com"
}

variable "lb_hostname_west" {
  description = "LoadBalancer hostname for the west region (set after k8s service deployment)"
  type        = string
  default     = "a0b4d78f4118d453fad680d95a45a628-1654497485.us-west-2.elb.amazonaws.com"
}

# =============================================================================
# Cross-Cloud Failover to Azure
# =============================================================================

variable "enable_cross_cloud_failover" {
  description = "Enable cross-cloud failover to Azure AKS"
  type        = bool
  default     = true
}

variable "azure_lb_ip_east" {
  description = "Azure AKS East US LoadBalancer IP (set after k8s service deployment)"
  type        = string
  default     = "4.157.63.47"
}

variable "azure_lb_ip_west" {
  description = "Azure AKS West US 2 LoadBalancer IP (set after k8s service deployment)"
  type        = string
  default     = "48.192.74.104"
}

# =============================================================================
# AWS Multi-Region Pool Configuration
# =============================================================================

variable "aws_pool_subdomain" {
  description = "Subdomain for the AWS weighted pool (creates aws-pool.multi-cloud.domain.com)"
  type        = string
  default     = "aws-pool"
}

variable "aws_east_weight" {
  description = "Weight for AWS East region in the weighted pool (0-255)"
  type        = number
  default     = 50
}

variable "aws_west_weight" {
  description = "Weight for AWS West region in the weighted pool (0-255)"
  type        = number
  default     = 50
}

# ELB Hosted Zone IDs for alias records
# Reference: https://docs.aws.amazon.com/general/latest/gr/elb.html
variable "elb_zone_id_east" {
  description = "ELB hosted zone ID for us-east-1"
  type        = string
  default     = "Z35SXDOTRQ7X7K" # us-east-1 Classic/ALB
}

variable "elb_zone_id_west" {
  description = "ELB hosted zone ID for us-west-2"
  type        = string
  default     = "Z1H1FL5HABSF5" # us-west-2 Classic/ALB
}
