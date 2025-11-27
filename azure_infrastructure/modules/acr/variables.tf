variable "registry_name" {
  description = "Name of the Azure Container Registry (must be globally unique, alphanumeric only)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.registry_name))
    error_message = "ACR name must be alphanumeric, 5-50 characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "primary_location" {
  description = "Primary Azure region for the registry"
  type        = string
  default     = "eastus"
}

variable "secondary_location" {
  description = "Secondary Azure region for geo-replication"
  type        = string
  default     = "westus2"
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy for geo-replicated region"
  type        = bool
  default     = false
}

variable "retention_days" {
  description = "Number of days to retain untagged manifests (mirrors ECR lifecycle policy)"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
