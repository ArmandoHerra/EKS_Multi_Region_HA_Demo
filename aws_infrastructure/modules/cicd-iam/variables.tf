variable "aws_region" {
  description = "AWS region to create resources in."
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID."
  type        = string
  default     = "933673765333"
}

variable "repository_name" {
  description = "Name of the ECR repository."
  type        = string
  default     = "basic-demo-microservice-01"
}

# Optional: If you want to restrict which GitHub repository/branch can assume the role, set this variable.
variable "github_oidc_subject" {
  description = "Optional OIDC subject condition (e.g., repo:my-org/my-repo:ref:refs/heads/main). Leave empty for no restriction."
  type        = string
  default     = "repo:ArmandoHerra/Go_Cloud_Native_Basic_Demo_Service_01:ref:refs/heads/main"
}
