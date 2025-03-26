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
