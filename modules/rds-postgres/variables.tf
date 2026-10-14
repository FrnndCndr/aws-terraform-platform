variable "product" {
  type        = string
  description = "SaaS product. Part of every resource name."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.product))
    error_message = "product must contain only lowercase letters, numbers and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Environment, dev or prod. Part of every resource name."
}

variable "vpc_id" {
  type        = string
  description = "VPC of the database."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnets, in at least two availability zones."

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids must contain at least two subnets."
  }
}

variable "allowed_security_group_ids" {
  type        = map(string)
  description = "Security groups allowed to connect to port 5432. Key: descriptive label."
  default     = {}
}

variable "engine_version" {
  type        = string
  description = "Major PostgreSQL version. AWS applies the minor versions."
  default     = "17"
}

variable "instance_class" {
  type        = string
  description = "Instance class of the database."
  default     = "db.t4g.micro"
}

variable "allocated_storage_gb" {
  type        = number
  description = "Initial storage, in GB."
  default     = 20

  validation {
    condition     = var.allocated_storage_gb >= 20
    error_message = "allocated_storage_gb must be at least 20."
  }
}

variable "max_allocated_storage_gb" {
  type        = number
  description = "Upper limit of storage autoscaling, in GB. Null disables it."
  default     = null
}

variable "db_name" {
  type        = string
  description = "Name of the database created with the instance."
  default     = "app"
}

variable "master_username" {
  type        = string
  description = "Master user of the database."
  default     = "postgres"
}

variable "multi_az" {
  type        = bool
  description = "Keeps a standby copy in another availability zone."
  default     = false
}

variable "backup_retention_days" {
  type        = number
  description = "Days the automated backups are kept."
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 1 and 35."
  }
}

variable "deletion_protection" {
  type        = bool
  description = "Prevents deleting the database."
  default     = true
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Deletes the database without a final snapshot."
  default     = false
}

variable "apply_immediately" {
  type        = bool
  description = "Applies database changes right away instead of in the maintenance window."
  default     = false
}

variable "master_password_rotation_days" {
  type        = number
  description = "Days between rotations of the managed master password. Null keeps the AWS default of 7 days."
  default     = null

  validation {
    condition     = var.master_password_rotation_days == null || (try(var.master_password_rotation_days >= 1 && var.master_password_rotation_days <= 1000, false))
    error_message = "master_password_rotation_days must be between 1 and 1000."
  }
}
