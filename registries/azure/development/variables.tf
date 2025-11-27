variable "registry_name" {
  description = "ACR name (globally unique)"
  type        = string
  default     = "aksmultiregiondemoacr"
}

variable "resource_group_name" {
  description = "Resource group for ACR"
  type        = string
  default     = "acr-registry-rg"
}

variable "primary_location" {
  type    = string
  default = "eastus"
}

variable "secondary_location" {
  type    = string
  default = "westus2"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "AKS MultiRegion Demo"
  }
}
