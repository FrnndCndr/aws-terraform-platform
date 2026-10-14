output "bucket_name" {
  description = "Name of the site bucket. Destination of the file upload."
  value       = aws_s3_bucket.site.id
}

output "bucket_arn" {
  description = "ARN of the site bucket."
  value       = aws_s3_bucket.site.arn
}

output "distribution_id" {
  description = "Identifier of the distribution. Used to invalidate the cache after a deployment."
  value       = aws_cloudfront_distribution.site.id
}

output "distribution_arn" {
  description = "ARN of the distribution."
  value       = aws_cloudfront_distribution.site.arn
}

output "distribution_domain_name" {
  description = "CloudFront domain name of the distribution."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "distribution_hosted_zone_id" {
  description = "Route 53 zone of CloudFront, target of alias records."
  value       = aws_cloudfront_distribution.site.hosted_zone_id
}
