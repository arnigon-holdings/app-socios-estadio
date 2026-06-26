output "collection_id" {
  description = "Rekognition collection ID"
  value       = aws_rekognition_collection.this.id
}

output "collection_arn" {
  description = "Rekognition collection ARN"
  value       = aws_rekognition_collection.this.arn
}
