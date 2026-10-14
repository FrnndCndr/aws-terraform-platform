output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "security_group_id" {
  description = "Security group of the tasks. Other modules allow traffic from it."
  value       = aws_security_group.service.id
}

output "task_role_name" {
  description = "Name of the task role."
  value       = aws_iam_role.task.name
}

output "task_role_arn" {
  description = "ARN of the task role."
  value       = aws_iam_role.task.arn
}

output "execution_role_arn" {
  description = "ARN of the role ECS uses to pull the image and read secrets."
  value       = aws_iam_role.execution.arn
}

output "service_discovery_service_arn" {
  description = "ARN of the Cloud Map service. Target of the API Gateway integration."
  value       = aws_service_discovery_service.this.arn
}

output "log_group_name" {
  description = "CloudWatch log group of the container."
  value       = aws_cloudwatch_log_group.service.name
}
