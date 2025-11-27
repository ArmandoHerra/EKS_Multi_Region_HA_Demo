terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
  required_version = ">= 1.12.0"
}

# Default provider - East US
provider "azurerm" {
  features {}
}

# Alias for West US 2
provider "azurerm" {
  alias = "west"
  features {}
}
