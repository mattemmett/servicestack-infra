locals {
  origin_id = "${var.name_prefix}-app-origin"

  # An API hostname serves dynamic routes at the root, so its default behavior must
  # neither cache nor reject write methods.
  default_cache_policy_id = var.default_caching_disabled ? data.aws_cloudfront_cache_policy.caching_disabled.id : data.aws_cloudfront_cache_policy.caching_optimized.id

  default_allowed_methods = var.default_caching_disabled ? ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"] : ["GET", "HEAD", "OPTIONS"]
}

variable "default_caching_disabled" {
  description = "Disable caching on the default behavior; use for hostnames that serve the API at the root"
  type        = bool
  default     = false
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
