### EAST ECR

output "main_ecr_repository_name" {
  value = module.ecr_primary.repository_name
}

output "main_ecr_repository_url" {
  value = module.ecr_primary.repository_url
}

### WEST ECR

output "secondary_ecr_repository_name" {
  value = module.ecr_secondary.repository_name
}

output "secondary_ecr_repository_url" {
  value = module.ecr_secondary.repository_url
}

### EAST EKS

output "eks_east_cluster_name" {
  description = "The name of the East EKS Cluster"
  value       = module.eks_cluster_east.cluster_name
}

output "eks_cluster_east_id" {
  description = "The ID of the Eas EKS cluster"
  value       = module.eks_cluster_east.cluster_id
}

output "eks_cluster_east_endpoint" {
  description = "The endpoint of the East EKS cluster"
  value       = module.eks_cluster_east.cluster_endpoint
}

output "eks_cluster_east_security_group_id" {
  description = "The security group ID of the East EKS cluster"
  value       = module.eks_cluster_east.cluster_security_group_id
}

### WEST EKS

output "eks_west_cluster_name" {
  description = "The name of the East EKS Cluster"
  value       = module.eks_cluster_east.cluster_name
}

output "eks_cluster_west_id" {
  description = "The ID of the EKS cluster in us-west-2"
  value       = module.eks_cluster_west.cluster_id
}

output "eks_cluster_west_endpoint" {
  description = "The endpoint of the EKS cluster in us-west-2"
  value       = module.eks_cluster_west.cluster_endpoint
}

output "eks_cluster_west_security_group_id" {
  description = "The security group ID of the EKS cluster in us-west-2"
  value       = module.eks_cluster_west.cluster_security_group_id
}
