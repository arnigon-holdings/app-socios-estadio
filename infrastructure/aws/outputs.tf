output "s3_bucket_id" {
  description = "S3 bucket name for face photos"
  value       = module.s3.bucket_id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.bucket_arn
}

output "rekognition_collection_id" {
  description = "Rekognition face collection ID"
  value       = module.rekognition.collection_id
}

output "rekognition_collection_arn" {
  description = "Rekognition face collection ARN"
  value       = module.rekognition.collection_arn
}

output "iam_role_arn" {
  description = "IAM role ARN to be assumed by Rails + Go service"
  value       = aws_iam_role.face_indexing.arn
}

output "iam_policy_arn" {
  description = "IAM policy ARN with least-privilege permissions"
  value       = aws_iam_policy.face_indexing.arn
}
