variable "domain_name" {
  type        = string
  description = "Main domain of the certificate, for example dev.example.com."
}

variable "subject_alternative_names" {
  type        = list(string)
  description = "Other domains covered by the same certificate."
  default     = []
}

variable "zone_id" {
  type        = string
  description = "Route 53 zone where the validation records are created."
}
