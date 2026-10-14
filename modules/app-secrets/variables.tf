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

variable "secret_names" {
  type        = list(string)
  description = "Names of the environment variables read from a secret, for example JWT_KEY. Uppercase letters, numbers and underscores only."
  default     = []

  validation {
    condition     = alltrue([for name in var.secret_names : can(regex("^[A-Z][A-Z0-9_]*$", name))])
    error_message = "Each secret name must start with an uppercase letter and contain only uppercase letters, numbers and underscores."
  }
}

variable "recovery_window_days" {
  type        = number
  description = "Days AWS keeps a deleted secret before removing it. 0 removes it immediately."
  default     = 7

  validation {
    condition     = var.recovery_window_days == 0 || (var.recovery_window_days >= 7 && var.recovery_window_days <= 30)
    error_message = "recovery_window_days must be 0 or between 7 and 30."
  }
}
