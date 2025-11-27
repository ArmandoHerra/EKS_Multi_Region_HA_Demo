output "ecr_primary_repository_url" {
  description = "The URL of the primary ECR repository"
  value       = module.ecr_primary.repository_url
}

output "ecr_secondary_repository_url" {
  description = "The URL of the secondary ECR repository"
  value       = module.ecr_secondary.repository_url
}

output "ecr_repo_arn" {
  description = "ARN for EKS IAM policy"
  value       = "arn:aws:ecr:us-east-1:${data.aws_caller_identity.current.account_id}:repository/${module.ecr_primary.repository_name}"
}

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}
