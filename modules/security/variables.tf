variable "name_prefix" {
  description = "Prefix used for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security groups"
  type        = string
}

variable "ssh_cidr_blocks" {
  description = "Allowed CIDR blocks for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "http_cidr_blocks" {
  description = "Allowed CIDR blocks for HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_cidr_blocks" {
  description = "Allowed CIDR blocks for HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}
