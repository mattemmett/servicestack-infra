variable "name_prefix" {
  description = "Prefix used for resource names"
  type        = string
}

variable "zone_name" {
  description = "Hosted zone name, for example service-stack.io"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name for the certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional names covered by the certificate, for example *.service-stack.io"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}
