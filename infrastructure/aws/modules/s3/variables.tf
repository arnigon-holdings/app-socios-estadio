variable "bucket_name" {
  description = "Globally unique S3 bucket name for face photos"
  type        = string
}

variable "force_destroy" {
  description = "Allow Terraform to delete the bucket even if it contains objects. Defaults to true so dev iteration works smoothly. Set to false in production to prevent accidental data loss."
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which noncurrent object versions expire"
  type        = number
  default     = 90
}

variable "enable_lifecycle" {
  description = "Whether to attach the lifecycle configuration"
  type        = bool
  default     = true
}
