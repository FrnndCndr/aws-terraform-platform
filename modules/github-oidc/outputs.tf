output "backend_role_arn" {
  description = "ARN of the backend deploy role. Null when it was not created. Value of role-to-assume in the workflow."
  value       = one(aws_iam_role.backend[*].arn)
}

output "frontend_role_arn" {
  description = "ARN of the frontend deploy role. Null when it was not created."
  value       = one(aws_iam_role.frontend[*].arn)
}
