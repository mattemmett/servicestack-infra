locals {
  origin_id = "${var.name_prefix}-app-origin"
}

variable "name_prefix" {
  description = "Prefix used for resource names"
  type        = string
}

variable "aliases" {
  description = "Hostnames served by this distribution, for example console.service-stack.io"
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "Validated ACM certificate ARN in us-east-1 covering every alias"
  type        = string
}

variable "origin_domain_name" {
  description = "Origin hostname, for example the EC2 host public DNS name"
  type        = string
}

variable "api_path_patterns" {
  description = "Path patterns routed to the API with caching disabled"
  type        = list(string)
  default     = ["/api/*"]
}

variable "price_class" {
  description = "CloudFront price class; PriceClass_100 is the lowest-cost tier"
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}
