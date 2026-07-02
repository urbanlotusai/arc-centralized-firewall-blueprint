output "transit_gateway_id" {
  description = "ID of the Transit Gateway."
  value       = module.transit_gateway.transit_gateway_id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway."
  value       = module.transit_gateway.transit_gateway_arn
}
