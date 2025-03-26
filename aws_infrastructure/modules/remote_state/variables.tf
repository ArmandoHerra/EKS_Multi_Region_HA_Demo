variable "bucket_name" {
  description = "The name of the S3 Bucket. Must be globally unique."
  type        = string
  default     = "eks-multi-region-ha-demo-state-bucket"
}

variable "table_name" {
  description = "The name of the DynamoDB Table. Must be unique in AWS Account."
  type        = string
  default     = "eks-multi-region-ha-demo-state-lock-table"
}