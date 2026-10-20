locals {
  custom_domain      = var.site_domain_name != null
  backend_subnet_ids = var.enable_nat_gateway ? module.network.private_subnet_ids : module.network.public_subnet_ids
  backend_image      = coalesce(var.backend_image, "${module.ecr.repository_url}:${var.backend_image_tag}")

  site_origins = concat(
    ["https://${module.static_site.distribution_domain_name}"],
    local.custom_domain ? ["https://${var.site_domain_name}"] : []
  )
}

module "network" {
  source = "../../modules/network"

  product            = var.product
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  excluded_zone_ids  = var.excluded_zone_ids
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
}

data "aws_route53_zone" "site" {
  count = local.custom_domain ? 1 : 0

  name         = var.dns_zone_name
  private_zone = false
}

module "site_certificate" {
  source = "../../modules/acm-certificate"
  count  = local.custom_domain ? 1 : 0

  domain_name = var.site_domain_name
  zone_id     = data.aws_route53_zone.site[0].zone_id
}

module "static_site" {
  source = "../../modules/static-site"

  product                = var.product
  environment            = var.environment
  force_destroy          = var.site_force_destroy
  price_class            = var.site_price_class
  domain_names           = local.custom_domain ? [var.site_domain_name] : []
  certificate_arn        = local.custom_domain ? module.site_certificate[0].certificate_arn : null
  dns_zone_id            = local.custom_domain ? data.aws_route53_zone.site[0].zone_id : null
  api_origin_domain_name = module.api_gateway.endpoint_domain_name
}

module "ecr" {
  source = "../../modules/ecr"

  product              = var.product
  environment          = var.environment
  service_name         = var.backend_service_name
  image_tag_mutability = var.ecr_image_tag_mutability
  force_delete         = var.ecr_force_delete
}

module "uploads_bucket" {
  source = "../../modules/uploads-bucket"

  product              = var.product
  environment          = var.environment
  cors_allowed_origins = local.site_origins
  versioning_enabled   = var.uploads_versioning
  force_destroy        = var.uploads_force_destroy
}

module "rds_postgres" {
  source = "../../modules/rds-postgres"

  product                       = var.product
  environment                   = var.environment
  vpc_id                        = module.network.vpc_id
  subnet_ids                    = module.network.private_subnet_ids
  engine_version                = var.db_engine_version
  instance_class                = var.db_instance_class
  allocated_storage_gb          = var.db_allocated_storage_gb
  max_allocated_storage_gb      = var.db_max_allocated_storage_gb
  db_name                       = var.db_name
  multi_az                      = var.db_multi_az
  backup_retention_days         = var.db_backup_retention_days
  deletion_protection           = var.db_deletion_protection
  skip_final_snapshot           = var.db_skip_final_snapshot
  apply_immediately             = var.db_apply_immediately
  master_password_rotation_days = var.db_password_rotation_days

  allowed_security_group_ids = {
    backend = module.ecs_service.security_group_id
  }
}

module "app_secrets" {
  source = "../../modules/app-secrets"

  product              = var.product
  environment          = var.environment
  secret_names         = var.backend_secrets
  recovery_window_days = var.secrets_recovery_window_days
}

module "ecs_service" {
  source = "../../modules/ecs-service"

  product                = var.product
  environment            = var.environment
  service_name           = var.backend_service_name
  vpc_id                 = module.network.vpc_id
  subnet_ids             = local.backend_subnet_ids
  assign_public_ip       = !var.enable_nat_gateway
  image                  = local.backend_image
  container_port         = var.backend_container_port
  cpu                    = var.backend_cpu
  memory                 = var.backend_memory
  cpu_architecture       = var.backend_cpu_architecture
  desired_count          = var.backend_desired_count
  health_check           = var.backend_health_check
  enable_execute_command = var.backend_enable_execute_command
  log_retention_days     = var.log_retention_days

  container_environment = merge(var.backend_environment, {
    (var.backend_env_names.db_host)        = module.rds_postgres.address
    (var.backend_env_names.db_port)        = tostring(module.rds_postgres.port)
    (var.backend_env_names.db_name)        = module.rds_postgres.db_name
    (var.backend_env_names.uploads_bucket) = module.uploads_bucket.bucket_name
  })

  secrets = merge(
    {
      (var.backend_env_names.db_username) = {
        secret_arn = module.rds_postgres.master_user_secret_arn
        json_key   = "username"
      }
      (var.backend_env_names.db_password) = {
        secret_arn = module.rds_postgres.master_user_secret_arn
        json_key   = "password"
      }
    },
    { for name, arn in module.app_secrets.secret_arns : name => { secret_arn = arn } }
  )

  task_role_policies = {
    uploads-bucket = module.uploads_bucket.read_write_policy_json
  }

  ingress_security_group_ids = {
    api-gateway = module.api_gateway.vpc_link_security_group_id
  }
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.github_owner == null ? 0 : 1

  url = "https://token.actions.githubusercontent.com"
}

module "github_oidc" {
  source = "../../modules/github-oidc"
  count  = var.github_owner == null ? 0 : 1

  product                = var.product
  environment            = var.environment
  oidc_provider_arn      = data.aws_iam_openid_connect_provider.github[0].arn
  github_owner           = var.github_owner
  github_owner_id        = var.github_owner_id
  github_environment     = coalesce(var.github_environment, var.environment)
  backend_repository     = var.github_backend_repository
  backend_repository_id  = var.github_backend_repository_id
  backend_service_name   = var.backend_service_name
  ecr_repository_arn     = module.ecr.repository_arn
  ecs_service_arn        = module.ecs_service.service_arn
  ecs_pass_role_arns     = [module.ecs_service.execution_role_arn, module.ecs_service.task_role_arn]
  frontend_repository    = var.github_frontend_repository
  frontend_repository_id = var.github_frontend_repository_id
  site_bucket_arn        = module.static_site.bucket_arn
  site_distribution_arn  = module.static_site.distribution_arn
}

module "api_gateway" {
  source = "../../modules/api-gateway"

  product                       = var.product
  environment                   = var.environment
  vpc_id                        = module.network.vpc_id
  vpc_cidr                      = module.network.vpc_cidr
  subnet_ids                    = module.network.private_subnet_ids
  service_discovery_service_arn = module.ecs_service.service_discovery_service_arn
  throttling_rate_limit         = var.api_throttling_rate_limit
  throttling_burst_limit        = var.api_throttling_burst_limit
  log_retention_days            = var.log_retention_days
}
