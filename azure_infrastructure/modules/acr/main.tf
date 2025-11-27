terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
  required_version = ">= 1.12.0"
}

resource "azurerm_container_registry" "main" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.primary_location
  sku                 = "Premium" # Required for geo-replication
  admin_enabled       = false

  # Geo-replication to secondary region
  georeplications {
    location                = var.secondary_location
    zone_redundancy_enabled = var.zone_redundancy_enabled
    tags                    = var.tags
  }

  # Retention policy for untagged manifests (similar to ECR lifecycle policy)
  retention_policy {
    days    = var.retention_days
    enabled = true
  }

  tags = var.tags
}
