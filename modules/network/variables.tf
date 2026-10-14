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

variable "vpc_cidr" {
  type        = string
  description = "CIDR range of the VPC, with a /16 mask."

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && try(split("/", var.vpc_cidr)[1] == "16", false)
    error_message = "vpc_cidr must be a valid CIDR range with a /16 mask."
  }
}

variable "az_count" {
  type        = number
  description = "Number of availability zones. Between 2 and 3."
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be between 2 and 3."
  }
}

variable "excluded_zone_ids" {
  type        = list(string)
  description = "Availability zone IDs that are never used, for example use1-az3."
  default     = []
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Creates NAT gateways and gives the private subnets outbound internet access."
  default     = false
}

variable "single_nat_gateway" {
  type        = bool
  description = "With NAT enabled: true creates one NAT gateway for all zones; false creates one per zone."
  default     = true
}
