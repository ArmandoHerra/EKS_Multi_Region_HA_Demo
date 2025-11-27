output "acr_registry_id" {
  description = "ACR resource ID for AKS role assignment"
  value       = module.acr.registry_id
}

output "acr_name" {
  description = "The name of the ACR"
  value       = module.acr.registry_name
}

output "acr_login_server" {
  description = "The login server URL for the ACR"
  value       = module.acr.login_server
}
