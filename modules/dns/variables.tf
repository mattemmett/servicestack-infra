variable "zone_name" {
  description = "Hosted zone name, for example service-stack.io"
  type        = string
}

variable "records" {
  description = "Route 53 A records to create in the hosted zone"
  type = map(object({
    name    = string
    ttl     = number
    records = list(string)
  }))
}

variable "alias_records" {
  description = "Route 53 alias A records, for example a CloudFront distribution"
  type = map(object({
    name                   = string
    target_dns_name        = string
    target_hosted_zone_id  = string
    evaluate_target_health = optional(bool, false)
  }))
  default = {}
}
