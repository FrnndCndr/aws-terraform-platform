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

variable "cors_allowed_origins" {
  type        = list(string)
  description = "Browser origins allowed to call the bucket, for example https://dev.example.com. Empty creates no CORS rule."
  default     = []
}

variable "versioning_enabled" {
  type        = bool
  description = "Keeps previous versions of every file."
  default     = false
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "With versioning, days a previous version is kept."
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days > 0
    error_message = "noncurrent_version_expiration_days must be greater than zero."
  }
}

variable "force_destroy" {
  type        = bool
  description = "Allows destroying the bucket even when it contains files."
  default     = false
}
