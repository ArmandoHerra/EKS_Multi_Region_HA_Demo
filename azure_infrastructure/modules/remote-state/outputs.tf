output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.state.name
}

output "container_name" {
  description = "Name of the blob container"
  value       = azurerm_storage_container.state.name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.state.name
}

output "primary_access_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.state.primary_access_key
  sensitive   = true
}
