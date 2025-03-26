# Primary ECR

output "main_ecr_repository_name" {
  value = module.ecr_primary.repository_name
}

output "main_ecr_repository_url" {
  value = module.ecr_primary.repository_url
}

# Secondary ECR

output "secondary_ecr_repository_name" {
  value = module.ecr_secondary.repository_name
}

output "secondary_ecr_repository_url" {
  value = module.ecr_secondary.repository_url
}