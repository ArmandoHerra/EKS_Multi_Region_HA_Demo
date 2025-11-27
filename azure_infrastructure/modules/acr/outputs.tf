output "registry_id" {
  description = "The resource ID of the ACR"
  value       = azurerm_container_registry.main.id
}

output "registry_name" {
  description = "The name of the ACR"
  value       = azurerm_container_registry.main.name
}

output "login_server" {
  description = "The login server URL for the ACR"
  value       = azurerm_container_registry.main.login_server
}
