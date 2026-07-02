output "zone_id" {
  description = "ID of the Route53 private hosted zone in the hub VPC."
  value       = module.route53.zone_id
}
