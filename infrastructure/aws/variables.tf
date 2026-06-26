variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "app-perfilamiento"
}

variable "environment" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "S3 bucket for face photos"
  type        = string
  default     = "perfilamiento-faces"
}

variable "rekognition_collection_id" {
  description = "Rekognition face collection ID"
  type        = string
  default     = "socios_stadium_users"
}

variable "iam_role_name" {
  description = "IAM role name assumed by Rails/Go service for face indexing + search"
  type        = string
  default     = null
}

variable "iam_policy_name" {
  description = "IAM policy name"
  type        = string
  default     = null
}

variable "s3_force_destroy" {
  description = "Allow Terraform to delete the S3 bucket even if it contains objects. Pass through to the s3 module. Set to false in production."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "app-perfilamiento"
    Component   = "face-indexing"
    Environment = "dev"
  }
}
