variable "product" {
  type        = string
  description = "Product that owns the domain. Lowercase letters, numbers and hyphens only."

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

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile of the client account."
}

variable "region" {
  type        = string
  description = "Region of the provider. Route 53 is global."
  default     = "us-east-1"
}

variable "project" {
  type        = string
  description = "Value of the project tag on all resources."
  default     = "aws-terraform-platform"
}

variable "domain_name" {
  type        = string
  description = "Domain of the client, for example example.com."
}
