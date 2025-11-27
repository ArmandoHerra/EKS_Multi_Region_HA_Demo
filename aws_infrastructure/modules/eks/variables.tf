variable "region" {
  description = "AWS region to deploy the cluster in"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.34"
}

variable "vpc_id" {
  description = "The VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs for the cluster"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to use for the cluster"
  type        = list(string)
  default = []
}

variable "eks_managed_node_groups" {
  description = "Map of managed node group configurations"
  type = map(object({
    desired_size = number
    max_size     = number
    min_size     = number
    instance_types    = list(string)
    key_name         = optional(string)
    additional_tags  = optional(map(string))
  }))
  default = {
    eks_nodes = {
      desired_size  = 3
      max_size      = 6
      min_size      = 1
      instance_types = ["t3.small"]
    }
  }
}

variable "tags" {
  description = "Tags to apply to the cluster and its resources"
  type        = map(string)
  default     = {}
}

variable "ecr_policy_arn" {
  description = "ARN of the IAM policy that grants read access to the ECR repository. This will be attached to node groups."
  type        = string
  default     = ""
}
