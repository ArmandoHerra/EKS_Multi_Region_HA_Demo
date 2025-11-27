# =============================================================================
# AKS East Outputs
# =============================================================================

output "aks_cluster_east_name" {
  description = "Name of the AKS cluster in East US"
  value       = module.aks_cluster_east.cluster_name
}

output "aks_cluster_east_fqdn" {
  description = "FQDN of the AKS cluster in East US"
  value       = module.aks_cluster_east.cluster_fqdn
}

# =============================================================================
# AKS West Outputs
# =============================================================================

output "aks_cluster_west_name" {
  description = "Name of the AKS cluster in West US 2"
  value       = module.aks_cluster_west.cluster_name
}

output "aks_cluster_west_fqdn" {
  description = "FQDN of the AKS cluster in West US 2"
  value       = module.aks_cluster_west.cluster_fqdn
}

# =============================================================================
# Resource Groups
# =============================================================================

output "resource_group_east" {
  description = "Name of the resource group in East US"
  value       = azurerm_resource_group.east.name
}

output "resource_group_west" {
  description = "Name of the resource group in West US 2"
  value       = azurerm_resource_group.west.name
}
