variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "basic-demo-microservice-01"
}

variable "remote_state_bucket" {
  type        = string
  description = "Remote State Bucket"
}
