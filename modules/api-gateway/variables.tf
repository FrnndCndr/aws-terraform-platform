variable "name_prefix" {
  type        = string
  description = "Prefix of the resource names, in the form <client>-<environment>."
}

variable "vpc_id" {
  type        = string
  description = "VPC where the backend runs."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR range of the VPC. The VPC link only sends traffic inside it."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets where the network interfaces of the VPC link are created."
}

variable "service_discovery_service_arn" {
  type        = string
  description = "ARN of the Cloud Map service where the backend tasks are registered."
}

variable "throttling_rate_limit" {
  type        = number
  description = "Sustained requests per second."
  default     = 50
}

variable "throttling_burst_limit" {
  type        = number
  description = "Requests accepted in a burst."
  default     = 100
}

variable "log_retention_days" {
  type        = number
  description = "Days the access logs are kept."
  default     = 7
}
