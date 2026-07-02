output "kms_key_arn" {
  description = "ARN of the KMS CMK used to encrypt firewall logs."
  value       = module.kms.key_arn
}

output "kms_key_id" {
  description = "ID (alias) of the KMS CMK."
  value       = module.kms.key_id
}

output "hub_vpc_id" {
  description = "ID of the hub (inspection) VPC."
  value       = module.network.vpc_id
}

output "hub_vpc_cidr" {
  description = "CIDR block of the hub VPC."
  value       = var.hub_vpc_cidr
}

output "network_firewall_arn" {
  description = "ARN of the AWS Network Firewall."
  value       = module.network_firewall.arn
}

output "network_firewall_id" {
  description = "ID of the AWS Network Firewall."
  value       = module.network_firewall.id
}

output "firewall_policy_arn" {
  description = "ARN of the Network Firewall policy."
  value       = module.network_firewall.policy_arn
}

output "transit_gateway_id" {
  description = "ID of the Transit Gateway."
  value       = module.transit_gateway.transit_gateway_id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway."
  value       = module.transit_gateway.transit_gateway_arn
}

output "s3_log_bucket" {
  description = "Name of the S3 bucket receiving firewall logs."
  value       = module.s3_logs.bucket_id
}

output "s3_log_bucket_arn" {
  description = "ARN of the S3 log bucket."
  value       = module.s3_logs.bucket_arn
}

output "route53_zone_id" {
  description = "ID of the Route53 private hosted zone in the hub VPC."
  value       = module.route53.zone_id
}
