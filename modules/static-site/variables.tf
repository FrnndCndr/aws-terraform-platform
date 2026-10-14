variable "name_prefix" {
  type        = string
  description = "Prefix of the resource names, in the form <client>-<environment>."
}

variable "force_destroy" {
  type        = bool
  description = "Allows destroying the bucket even when it contains files."
  default     = false
}

variable "price_class" {
  type        = string
  description = "Set of CloudFront locations. PriceClass_100 uses North America and Europe."
  default     = "PriceClass_100"
}

variable "domain_names" {
  type        = list(string)
  description = "Custom domain names of the distribution. Empty uses the CloudFront domain."
  default     = []
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate in us-east-1. Required when domain_names is not empty."
  default     = null

  validation {
    condition     = length(var.domain_names) == 0 || var.certificate_arn != null
    error_message = "certificate_arn is required when domain_names is not empty."
  }
}

variable "dns_zone_id" {
  type        = string
  description = "Route 53 zone where the alias records of domain_names are created. Null creates no records."
  default     = null
}

variable "api_origin_domain_name" {
  type        = string
  description = "DNS name of the backend. When set, API routing is created."
  default     = null
}

variable "api_path_pattern" {
  type        = string
  description = "Path pattern forwarded to the backend."
  default     = "/api/*"
}

variable "api_origin_protocol_policy" {
  type        = string
  description = "Protocol used to reach the backend: https-only or http-only."
  default     = "https-only"

  validation {
    condition     = contains(["http-only", "https-only"], var.api_origin_protocol_policy)
    error_message = "api_origin_protocol_policy must be http-only or https-only."
  }
}
