variable "namespace" {
  description = "Organization or team namespace"
  type        = string
  default     = "arc"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "arc-centralized-firewall-blueprint"
  }
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state (used to read 03-network and 02-s3 remote state)"
  type        = string
}

variable "blocked_domains" {
  description = "List of domains to block in the Network Firewall stateful rule group (e.g. malware C2 domains)."
  type        = list(string)
  default     = ["malware.example.com", "badactor.example.net"]
}
