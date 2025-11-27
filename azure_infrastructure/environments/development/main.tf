# =============================================================================
# Resource Groups
# =============================================================================

resource "azurerm_resource_group" "east" {
  name     = "${var.project_name}-${var.environment}-east-rg"
  location = var.azure_region_east
  tags     = var.tags
}

resource "azurerm_resource_group" "west" {
  provider = azurerm.west
  name     = "${var.project_name}-${var.environment}-west-rg"
  location = var.azure_region_west
  tags     = var.tags
}

# =============================================================================
# ACR with Geo-Replication (single instance, replicated to both regions)
# =============================================================================

module "acr" {
  source = "../../modules/acr"

  registry_name       = var.registry_name
  resource_group_name = azurerm_resource_group.east.name
  primary_location    = var.azure_region_east
  secondary_location  = var.azure_region_west
  tags                = var.tags
}

# =============================================================================
# AKS Cluster - East US
# =============================================================================

module "aks_cluster_east" {
  source = "../../modules/aks"

  cluster_name        = "${var.cluster_name}-east"
  location            = var.azure_region_east
  resource_group_name = azurerm_resource_group.east.name
  dns_prefix          = "${var.cluster_name}-east"
  kubernetes_version  = var.kubernetes_version
  node_count          = var.node_count
  vm_size             = var.vm_size
  min_count           = var.min_count
  max_count           = var.max_count
  acr_id              = module.acr.registry_id
  enable_acr_pull     = true
  tags                = var.tags
}

# =============================================================================
# AKS Cluster - West US 2
# =============================================================================

module "aks_cluster_west" {
  source = "../../modules/aks"
  providers = {
    azurerm = azurerm.west
  }

  cluster_name        = "${var.cluster_name}-west"
  location            = var.azure_region_west
  resource_group_name = azurerm_resource_group.west.name
  dns_prefix          = "${var.cluster_name}-west"
  kubernetes_version  = var.kubernetes_version
  node_count          = var.node_count
  vm_size             = var.vm_size
  min_count           = var.min_count
  max_count           = var.max_count
  acr_id              = module.acr.registry_id
  enable_acr_pull     = true
  tags                = var.tags
}
