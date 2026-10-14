locals {
  name_prefix        = "${var.client}-${var.environment}"
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

  name_prefix        = local.name_prefix
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

  name_prefix            = local.name_prefix
  force_destroy          = var.site_force_destroy
  price_class            = var.site_price_class
  domain_names           = local.custom_domain ? [var.site_domain_name] : []
  certificate_arn        = local.custom_domain ? module.site_certificate[0].certificate_arn : null
  dns_zone_id            = local.custom_domain ? data.aws_route53_zone.site[0].zone_id : null
  api_origin_domain_name = module.api_gateway.endpoint_domain_name
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix          = local.name_prefix
  image_tag_mutability = var.ecr_image_tag_mutability
  force_delete         = var.ecr_force_delete
}

module "uploads_bucket" {
  source = "../../modules/uploads-bucket"

  name_prefix          = local.name_prefix
  cors_allowed_origins = local.site_origins
  versioning_enabled   = var.uploads_versioning
  force_destroy        = var.uploads_force_destroy
}

module "rds_postgres" {
  source = "../../modules/rds-postgres"

  name_prefix                   = local.name_prefix
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

module "ecs_service" {
  source = "../../modules/ecs-service"

  name_prefix            = local.name_prefix
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

  environment = merge(var.backend_environment, {
    DB_HOST        = module.rds_postgres.address
    DB_PORT        = tostring(module.rds_postgres.port)
    DB_NAME        = module.rds_postgres.db_name
    UPLOADS_BUCKET = module.uploads_bucket.bucket_name
  })

  secrets = {
    DB_USERNAME = {
      secret_arn = module.rds_postgres.master_user_secret_arn
      json_key   = "username"
    }
    DB_PASSWORD = {
      secret_arn = module.rds_postgres.master_user_secret_arn
      json_key   = "password"
    }
  }

  task_role_policies = {
    uploads-bucket = module.uploads_bucket.read_write_policy_json
  }

  ingress_security_group_ids = {
    api-gateway = module.api_gateway.vpc_link_security_group_id
  }
}

module "api_gateway" {
  source = "../../modules/api-gateway"

  name_prefix                   = local.name_prefix
  vpc_id                        = module.network.vpc_id
  vpc_cidr                      = module.network.vpc_cidr
  subnet_ids                    = module.network.private_subnet_ids
  service_discovery_service_arn = module.ecs_service.service_discovery_service_arn
  throttling_rate_limit         = var.api_throttling_rate_limit
  throttling_burst_limit        = var.api_throttling_burst_limit
  log_retention_days            = var.log_retention_days
}
