variable "name_prefix" {
  type        = string
  description = "Prefix of the resource names, in the form <client>-<environment>."
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
