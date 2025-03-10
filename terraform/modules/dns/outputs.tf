output "domain_name" {
  description = "The domain name of the application"
  value       = var.domain_name
}

output "zone_id" {
  description = "The zone ID of the Route53 zone"
  value       = data.aws_route53_zone.main.zone_id
} 