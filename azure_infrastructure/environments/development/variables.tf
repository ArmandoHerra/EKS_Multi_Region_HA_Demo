variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "aks-multiregion-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "azure_region_east" {
  description = "Primary Azure region"
  type        = string
  default     = "eastus"
}

variable "azure_region_west" {
  description = "Secondary Azure region"
  type        = string
  default     = "westus2"
}

variable "registry_name" {
  description = "Name of the ACR (must be globally unique, alphanumeric only)"
  type        = string
  default     = "aksmultiregiondemoacr"
}

variable "cluster_name" {
  description = "Base name for the AKS clusters"
  type        = string
  default     = "aks-cluster-dev"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.34"
}

variable "node_count" {
  description = "Number of nodes per cluster"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "VM size for AKS nodes (similar to t3.small)"
  type        = string
  default     = "Standard_B2s"
}

variable "min_count" {
  description = "Minimum node count for autoscaling"
  type        = number
  default     = 3
}

variable "max_count" {
  description = "Maximum node count for autoscaling"
  type        = number
  default     = 6
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "AKS MultiRegion Demo"
  }
}
