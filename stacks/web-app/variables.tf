variable "product" {
  type        = string
  description = "SaaS product. Prefix of every resource name. Lowercase letters, numbers and hyphens only."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.product))
    error_message = "product must contain only lowercase letters, numbers and hyphens."
  }
}

variable "client" {
  type        = string
  description = "Company that owns the product. Used as a tag. Lowercase letters, numbers and hyphens only."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client))
    error_message = "client must contain only lowercase letters, numbers and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Environment: dev or prod."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile Terraform uses to connect to the client account."
}

variable "region" {
  type        = string
  description = "Region of the resources."
  default     = "us-east-1"
}

variable "project" {
  type        = string
  description = "Value of the project tag on all resources."
  default     = "aws-terraform-platform"
}

variable "log_retention_days" {
  type        = number
  description = "Days the backend and API logs are kept."
  default     = 7
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR range of the VPC, with a /16 mask."
}

variable "az_count" {
  type        = number
  description = "Number of availability zones."
  default     = 2
}

variable "excluded_zone_ids" {
  type        = list(string)
  description = "Availability zone IDs that are never used."
  default     = ["use1-az3"]
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Creates NAT gateways. With NAT, the backend tasks move to the private subnets without a public IP."
  default     = false
}

variable "single_nat_gateway" {
  type        = bool
  description = "With NAT enabled, a single NAT gateway for all zones."
  default     = true
}

variable "site_force_destroy" {
  type        = bool
  description = "Allows destroying the site bucket even when it contains files."
  default     = false
}

variable "site_price_class" {
  type        = string
  description = "Set of CloudFront locations."
  default     = "PriceClass_100"
}

variable "dns_zone_name" {
  type        = string
  description = "Route 53 zone of the custom domain, created by the dns-zone stack."
  default     = null
}

variable "site_domain_name" {
  type        = string
  description = "Domain of the site in this environment, for example dev.example.com. Null uses the CloudFront domain."
  default     = null

  validation {
    condition     = var.site_domain_name == null || (var.dns_zone_name != null && var.region == "us-east-1")
    error_message = "site_domain_name requires dns_zone_name and region us-east-1, because CloudFront only accepts certificates from us-east-1."
  }
}

variable "backend_service_name" {
  type        = string
  description = "Name of the backend service, its container and its image repository."
  default     = "backend"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.backend_service_name))
    error_message = "backend_service_name must contain only lowercase letters, numbers and hyphens."
  }
}

variable "backend_image" {
  type        = string
  description = "Full backend image. Null uses the ECR repository of the environment with backend_image_tag."
  default     = null
}

variable "backend_image_tag" {
  type        = string
  description = "Image tag in the ECR repository."
  default     = "latest"
}

variable "backend_container_port" {
  type        = number
  description = "Port the backend listens on."
  default     = 8080
}

variable "backend_cpu" {
  type        = number
  description = "Task CPU, in units where 1024 is one vCPU."
  default     = 256
}

variable "backend_memory" {
  type        = number
  description = "Task memory, in MB."
  default     = 512
}

variable "backend_cpu_architecture" {
  type        = string
  description = "X86_64 or ARM64."
  default     = "X86_64"
}

variable "backend_desired_count" {
  type        = number
  description = "Number of backend tasks."
  default     = 1
}

variable "backend_environment" {
  type        = map(string)
  description = "Additional environment variables of the backend."
  default     = {}
}

variable "backend_health_check" {
  type = object({
    command              = list(string)
    interval_seconds     = optional(number, 30)
    timeout_seconds      = optional(number, 5)
    retries              = optional(number, 3)
    start_period_seconds = optional(number, 30)
  })
  description = "Container health check of the backend. Null disables it."
  default     = null
}

variable "backend_enable_execute_command" {
  type        = bool
  description = "Allows opening a shell in the backend container with ECS Exec."
  default     = false
}

variable "ecr_image_tag_mutability" {
  type        = string
  description = "MUTABLE or IMMUTABLE."
  default     = "MUTABLE"
}

variable "ecr_force_delete" {
  type        = bool
  description = "Allows destroying the ECR repository even when it contains images."
  default     = false
}

variable "api_throttling_rate_limit" {
  type        = number
  description = "Sustained requests per second in API Gateway."
  default     = 50
}

variable "api_throttling_burst_limit" {
  type        = number
  description = "Burst limit in API Gateway."
  default     = 100
}

variable "db_name" {
  type        = string
  description = "Name of the database."
  default     = "app"
}

variable "db_engine_version" {
  type        = string
  description = "Major PostgreSQL version."
  default     = "17"
}

variable "db_instance_class" {
  type        = string
  description = "Instance class of the database."
  default     = "db.t4g.micro"
}

variable "db_allocated_storage_gb" {
  type        = number
  description = "Initial storage, in GB."
  default     = 20
}

variable "db_max_allocated_storage_gb" {
  type        = number
  description = "Upper limit of storage autoscaling, in GB. Null disables it."
  default     = null
}

variable "db_multi_az" {
  type        = bool
  description = "Keeps a standby copy of the database in another zone."
  default     = false
}

variable "db_backup_retention_days" {
  type        = number
  description = "Days the automated backups are kept."
  default     = 7
}

variable "db_deletion_protection" {
  type        = bool
  description = "Prevents deleting the database."
  default     = true
}

variable "db_skip_final_snapshot" {
  type        = bool
  description = "Deletes the database without a final snapshot."
  default     = false
}

variable "db_apply_immediately" {
  type        = bool
  description = "Applies database changes right away."
  default     = false
}

variable "db_password_rotation_days" {
  type        = number
  description = "Days between rotations of the managed master password."
  default     = 365
}

variable "uploads_versioning" {
  type        = bool
  description = "Versioning of the uploads bucket."
  default     = false
}

variable "uploads_force_destroy" {
  type        = bool
  description = "Allows destroying the uploads bucket even when it contains files."
  default     = false
}
