output "distribution_id" {
  value = aws_cloudfront_distribution.this.id
}

output "domain_name" {
  description = "CloudFront domain name used as the Route 53 alias target"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "CloudFront hosted zone ID used as the Route 53 alias target"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}
