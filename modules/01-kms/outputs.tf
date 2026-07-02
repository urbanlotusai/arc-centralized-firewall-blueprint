output "key_arn" {
  description = "ARN of the KMS CMK used to encrypt firewall logs."
  value       = module.kms.key_arn
}

output "key_id" {
  description = "ID (alias) of the KMS CMK."
  value       = module.kms.key_id
}
