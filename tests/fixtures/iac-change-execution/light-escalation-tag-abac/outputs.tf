output "bucket_name" {
  description = "Exports bucket name"
  value       = aws_s3_bucket.exports.bucket
}

output "bucket_arn" {
  description = "Exports bucket ARN"
  value       = aws_s3_bucket.exports.arn
}
