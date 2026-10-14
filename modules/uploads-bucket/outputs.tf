output "bucket_name" {
  description = "Name of the uploads bucket."
  value       = aws_s3_bucket.uploads.id
}

output "bucket_arn" {
  description = "ARN of the uploads bucket."
  value       = aws_s3_bucket.uploads.arn
}

output "read_write_policy_json" {
  description = "IAM policy that allows listing the bucket and reading, writing and deleting its objects."
  value       = data.aws_iam_policy_document.read_write.json
}
