variable "name_prefix" {
  type        = string
  description = "Prefix of the resource names, in the form <client>-<environment>."
}

variable "service_name" {
  type        = string
  description = "Name of the service and of its container."
  default     = "backend"
}

variable "vpc_id" {
  type        = string
  description = "VPC where the tasks run."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets where the tasks run."
}

variable "assign_public_ip" {
  type        = bool
  description = "Gives each task a public IP. Required in public subnets without a NAT gateway."
  default     = false
}

variable "image" {
  type        = string
  description = "Container image, with its tag."
}

variable "container_port" {
  type        = number
  description = "Port the container listens on."
  default     = 8080
}

variable "cpu" {
  type        = number
  description = "Task CPU, in units where 1024 is one vCPU."
  default     = 256
}

variable "memory" {
  type        = number
  description = "Task memory, in MB."
  default     = 512
}

variable "cpu_architecture" {
  type        = string
  description = "X86_64 or ARM64. Must match the architecture of the image."
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be X86_64 or ARM64."
  }
}

variable "desired_count" {
  type        = number
  description = "Number of tasks. Zero stops the service without destroying it."
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count cannot be negative."
  }
}

variable "environment" {
  type        = map(string)
  description = "Environment variables of the container."
  default     = {}
}

variable "secrets" {
  type = map(object({
    secret_arn = string
    json_key   = optional(string)
  }))
  description = "Environment variables read from Secrets Manager. Key: variable name. json_key selects a field of a JSON secret."
  default     = {}
}

variable "task_role_policies" {
  type        = map(string)
  description = "IAM policies, as JSON, attached to the task role. Key: policy name."
  default     = {}
}

variable "ingress_security_group_ids" {
  type        = map(string)
  description = "Security groups allowed to reach the container port. Key: descriptive label."
  default     = {}
}

variable "health_check" {
  type = object({
    command              = list(string)
    interval_seconds     = optional(number, 30)
    timeout_seconds      = optional(number, 5)
    retries              = optional(number, 3)
    start_period_seconds = optional(number, 30)
  })
  description = "Container health check. Null disables it."
  default     = null
}

variable "enable_execute_command" {
  type        = bool
  description = "Allows opening a shell in the container with ECS Exec."
  default     = false
}

variable "log_retention_days" {
  type        = number
  description = "Days the container logs are kept."
  default     = 7
}
