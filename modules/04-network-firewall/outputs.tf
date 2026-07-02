output "arn" {
  description = "ARN of the AWS Network Firewall."
  value       = module.network_firewall.arn
}

output "id" {
  description = "ID of the AWS Network Firewall."
  value       = module.network_firewall.id
}

output "policy_arn" {
  description = "ARN of the Network Firewall policy."
  value       = module.network_firewall.policy_arn
}
