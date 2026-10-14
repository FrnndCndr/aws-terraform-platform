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

variable "service_name" {
  type        = string
  description = "Name of the service that owns the images."
  default     = "backend"
}

variable "image_tag_mutability" {
  type        = string
  description = "MUTABLE allows reusing a tag such as latest; IMMUTABLE forbids it."
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "max_image_count" {
  type        = number
  description = "Number of images kept in the repository."
  default     = 10

  validation {
    condition     = var.max_image_count >= 1
    error_message = "max_image_count must be at least 1."
  }
}

variable "force_delete" {
  type        = bool
  description = "Allows destroying the repository even when it contains images."
  default     = false
}
