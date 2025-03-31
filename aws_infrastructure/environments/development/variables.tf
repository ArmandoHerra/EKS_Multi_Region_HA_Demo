variable "aws_region" {
  description = "The AWS region for the primary resources."
  type        = string
  default     = "us-east-1"
}

variable "repository_name" {
  description = "Name of the ECR repository to create."
  type        = string
  default     = "basic-demo-microservice-01"
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
  default     = "1.32"
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
      desired_capacity = 3
      max_capacity     = 6
      min_capacity     = 1
      instance_type    = "t3.medium"
      key_name         = ""
      additional_tags  = {}
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
