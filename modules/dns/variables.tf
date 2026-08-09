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
