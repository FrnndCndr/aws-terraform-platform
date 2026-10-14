output "certificate_arn" {
  description = "ARN of the certificate, available once ACM has issued it."
  value       = aws_acm_certificate_validation.this.certificate_arn
}
