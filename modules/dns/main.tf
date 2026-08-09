data "aws_route53_zone" "this" {
  name         = var.zone_name
  private_zone = false
}

resource "aws_route53_record" "this" {
  for_each = var.records

  allow_overwrite = true
  zone_id = data.aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = "A"
  ttl     = each.value.ttl
  records = each.value.records
}
