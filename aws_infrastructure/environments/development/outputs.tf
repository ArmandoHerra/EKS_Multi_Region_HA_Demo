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

### Route53

output "route53_zone_id" {
  description = "The Route53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "route53_failover_fqdn" {
  description = "The fully qualified domain name for the failover record"
  value       = "${var.subdomain}.${var.domain_name}"
}

output "route53_health_check_east_id" {
  description = "The health check ID for the east region"
  value       = length(aws_route53_health_check.east) > 0 ? aws_route53_health_check.east[0].id : null
}

output "route53_health_check_west_id" {
  description = "The health check ID for the west region"
  value       = length(aws_route53_health_check.west) > 0 ? aws_route53_health_check.west[0].id : null
}
