output "secret_arns" {
  description = "Map of environment variable name to secret ARN."
  value       = { for name, secret in aws_secretsmanager_secret.this : name => secret.arn }
}
