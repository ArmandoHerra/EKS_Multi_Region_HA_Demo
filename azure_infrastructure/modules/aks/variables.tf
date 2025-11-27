variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region for the cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.34"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "VM size for nodes (equivalent to EKS instance types)"
  type        = string
  default     = "Standard_B2s"
}

variable "enable_auto_scaling" {
  description = "Enable cluster autoscaler"
  type        = bool
  default     = true
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

variable "acr_id" {
  description = "Resource ID of the ACR to grant pull permissions"
  type        = string
  default     = ""
}

variable "enable_acr_pull" {
  description = "Enable ACR pull role assignment (set to true when acr_id is provided)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the cluster and its resources"
  type        = map(string)
  default     = {}
}
