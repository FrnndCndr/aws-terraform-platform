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

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the GitHub OIDC provider of the account."
}

variable "github_owner" {
  type        = string
  description = "GitHub organization or user that owns the repositories."
}

variable "github_owner_id" {
  type        = string
  description = "Numeric id of the GitHub owner. Set it when the repositories emit the immutable subject. Null uses the subject by name."
  default     = null
}

variable "github_environment" {
  type        = string
  description = "GitHub environment the deployments run from, for example dev."
}

variable "backend_repository" {
  type        = string
  description = "Backend repository, without the owner. Null does not create the backend role."
  default     = null
}

variable "backend_repository_id" {
  type        = string
  description = "Numeric id of the backend repository. Required with github_owner_id and backend_repository."
  default     = null

  validation {
    condition     = var.github_owner_id == null || var.backend_repository == null || var.backend_repository_id != null
    error_message = "backend_repository_id is required when github_owner_id and backend_repository are set."
  }
}

variable "backend_service_name" {
  type        = string
  description = "Purpose of the backend service in the role name."
  default     = "backend"
}

variable "ecr_repository_arn" {
  type        = string
  description = "ECR repository of the environment. Required with backend_repository."
  default     = null

  validation {
    condition     = var.backend_repository == null || var.ecr_repository_arn != null
    error_message = "ecr_repository_arn is required when backend_repository is set."
  }
}

variable "ecs_service_arn" {
  type        = string
  description = "ECS service of the environment. Required with backend_repository."
  default     = null

  validation {
    condition     = var.backend_repository == null || var.ecs_service_arn != null
    error_message = "ecs_service_arn is required when backend_repository is set."
  }
}

variable "ecs_pass_role_arns" {
  type        = list(string)
  description = "Execution role and task role of the service. Required with backend_repository."
  default     = []

  validation {
    condition     = var.backend_repository == null || length(var.ecs_pass_role_arns) > 0
    error_message = "ecs_pass_role_arns is required when backend_repository is set."
  }
}

variable "frontend_repository" {
  type        = string
  description = "Frontend repository, without the owner. Null does not create the frontend role."
  default     = null
}

variable "frontend_repository_id" {
  type        = string
  description = "Numeric id of the frontend repository. Required with github_owner_id and frontend_repository."
  default     = null

  validation {
    condition     = var.github_owner_id == null || var.frontend_repository == null || var.frontend_repository_id != null
    error_message = "frontend_repository_id is required when github_owner_id and frontend_repository are set."
  }
}

variable "site_bucket_arn" {
  type        = string
  description = "Site bucket. Required with frontend_repository."
  default     = null

  validation {
    condition     = var.frontend_repository == null || var.site_bucket_arn != null
    error_message = "site_bucket_arn is required when frontend_repository is set."
  }
}

variable "site_distribution_arn" {
  type        = string
  description = "CloudFront distribution of the site. Required with frontend_repository."
  default     = null

  validation {
    condition     = var.frontend_repository == null || var.site_distribution_arn != null
    error_message = "site_distribution_arn is required when frontend_repository is set."
  }
}
