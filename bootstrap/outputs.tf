output "bucket_name" {
  description = "Name of the state bucket. Use as bucket when initializing a stack backend."
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "ARN of the state bucket."
  value       = aws_s3_bucket.state.arn
}

output "bucket_region" {
  description = "Region of the state bucket. Use as region when initializing a stack backend."
  value       = aws_s3_bucket.state.region
}
