output "certificate_arn" {
  description = "Validated certificate ARN, safe to attach to CloudFront"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "domain_name" {
  value = aws_acm_certificate.this.domain_name
}
