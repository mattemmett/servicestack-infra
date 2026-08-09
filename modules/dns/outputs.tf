output "zone_id" {
  value = data.aws_route53_zone.this.zone_id
}

output "record_fqdns" {
  value = { for key, record in aws_route53_record.this : key => record.fqdn }
}
