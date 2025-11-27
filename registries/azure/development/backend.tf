terraform {
  backend "azurerm" {
    key = "acr/terraform.tfstate"
  }
}
