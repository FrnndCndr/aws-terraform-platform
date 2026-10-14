variable "client" {
  type        = string
  description = "Client identifier. Part of the bucket name. Lowercase letters, numbers and hyphens only."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client))
    error_message = "client must contain only lowercase letters, numbers and hyphens."
  }
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile Terraform uses to connect to the client account."
}

variable "region" {
  type        = string
  description = "Region where the bucket is created."
  default     = "us-east-1"
}

variable "project" {
  type        = string
  description = "Value of the project tag on all resources."
  default     = "aws-terraform-platform"
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Days a noncurrent state version is kept before it is deleted."
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days > 0
    error_message = "noncurrent_version_expiration_days must be greater than zero."
  }
}
