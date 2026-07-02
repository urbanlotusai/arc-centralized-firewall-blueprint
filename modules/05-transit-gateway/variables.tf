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
  description = "S3 bucket name for Terraform state (used to read 03-network remote state)"
  type        = string
}

variable "tgw_name" {
  description = "Name suffix for the Transit Gateway."
  type        = string
  default     = "hub-transit-gateway"
}

# Spoke VPCs are attached to the Transit Gateway and route through the hub.
variable "spoke_vpc_id" {
  description = "ID of the first spoke VPC to attach to the Transit Gateway."
  type        = string
  default     = "vpc-0abc123def456789"
}

variable "spoke_subnet_ids" {
  description = "Subnet IDs in the spoke VPC for the TGW attachment."
  type        = list(string)
  default     = ["subnet-0aaa111bbb222ccc3", "subnet-0ddd444eee555fff6"]
}

variable "spoke_cidr" {
  description = "CIDR of the spoke VPC — added as a TGW route target for routing through the firewall."
  type        = string
  default     = "10.0.0.0/8"
}
