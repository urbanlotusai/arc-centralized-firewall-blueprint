output "bucket_id" {
  description = "Name of the S3 bucket receiving firewall logs."
  value       = module.s3_logs.bucket_id
}

output "bucket_arn" {
  description = "ARN of the S3 log bucket."
  value       = module.s3_logs.bucket_arn
}
