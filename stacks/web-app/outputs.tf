output "vpc_id" {
  description = "Identifier of the VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnets."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnets."
  value       = module.network.private_subnet_ids
}

output "site_bucket_name" {
  description = "Bucket where the site files are uploaded."
  value       = module.static_site.bucket_name
}

output "site_distribution_id" {
  description = "CloudFront distribution, used to invalidate the cache."
  value       = module.static_site.distribution_id
}

output "site_url" {
  description = "URL of the site."
  value       = local.custom_domain ? "https://${var.site_domain_name}" : "https://${module.static_site.distribution_domain_name}"
}

output "ecr_repository_url" {
  description = "Destination of docker push for the backend."
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster of the backend."
  value       = module.ecs_service.cluster_name
}

output "ecs_service_name" {
  description = "ECS service of the backend. Used to force a new deployment."
  value       = module.ecs_service.service_name
}

output "backend_log_group_name" {
  description = "CloudWatch log group of the backend."
  value       = module.ecs_service.log_group_name
}

output "api_endpoint" {
  description = "API Gateway endpoint."
  value       = module.api_gateway.api_endpoint
}

output "db_address" {
  description = "Address of the database."
  value       = module.rds_postgres.address
}

output "db_secret_arn" {
  description = "Secret with the database username and password."
  value       = module.rds_postgres.master_user_secret_arn
}

output "uploads_bucket_name" {
  description = "Bucket of the uploaded files."
  value       = module.uploads_bucket.bucket_name
}

output "ecs_task_definition_family" {
  description = "Family of the backend task definition. The deployment takes its latest revision."
  value       = module.ecs_service.task_definition_family
}

output "backend_container_name" {
  description = "Backend container inside the task definition."
  value       = module.ecs_service.container_name
}

output "github_backend_role_arn" {
  description = "Role the backend workflow assumes. Null without deployment from GitHub."
  value       = one(module.github_oidc[*].backend_role_arn)
}

output "github_frontend_role_arn" {
  description = "Role the frontend workflow assumes. Null without deployment from GitHub."
  value       = one(module.github_oidc[*].frontend_role_arn)
}
