resource "azurerm_resource_group" "acr" {
  name     = var.resource_group_name
  location = var.primary_location
  tags     = var.tags
}

module "acr" {
  source = "../../../azure_infrastructure/modules/acr"

  registry_name       = var.registry_name
  resource_group_name = azurerm_resource_group.acr.name
  primary_location    = var.primary_location
  secondary_location  = var.secondary_location
  tags                = var.tags
}
