# ── Mandatory ─────────────────────────────────────────────────────────────────

variable "environment" {
  description = "Deployment environment (e.g. prod, staging, dev)."
  type        = string
}

variable "namespace" {
  description = "Project or team namespace used as a resource name prefix."
  type        = string
}

# Spoke VPCs are attached to the Transit Gateway and route through the hub.
# Provide the VPC ID, route table IDs, and subnet IDs for each spoke.
variable "spoke_vpc_id" {
  description = "ID of the first spoke VPC to attach to the Transit Gateway."
  type        = string
}

variable "spoke_subnet_ids" {
  description = "Subnet IDs in the spoke VPC for the TGW attachment."
  type        = list(string)
}

variable "spoke_route_table_ids" {
  description = "Route table IDs in the spoke VPC to point at the TGW for hub-bound traffic."
  type        = list(string)
}

variable "spoke_account_ids" {
  description = "List of AWS account IDs owning spoke VPCs (for RAM resource sharing)."
  type        = list(any)
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "hub_vpc_cidr" {
  description = "CIDR block for the hub (inspection) VPC."
  type        = string
  default     = "100.64.0.0/16"
}

variable "spoke_cidr" {
  description = "CIDR of the spoke VPC — added as a TGW route target for routing through the firewall."
  type        = string
  default     = "10.0.0.0/8"
}

variable "kms_deletion_window" {
  description = "Days before KMS key deletion takes effect (7–30)."
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "Days to retain firewall logs in S3 before expiring."
  type        = number
  default     = 90
}

variable "blocked_domains" {
  description = "List of domains to block in the Network Firewall stateful rule group (e.g. malware C2 domains)."
  type        = list(string)
  default     = ["malware.example.com", "badactor.example.net"]
}

variable "tgw_name" {
  description = "Name for the Transit Gateway."
  type        = string
  default     = "hub-transit-gateway"
}

variable "compliance_profile" {
  description = "Compliance overlay: 'general' (default), 'hipaa', or 'pci_dss'. Drives log retention and deletion protection."
  type        = string
  default     = "general"

  validation {
    condition     = contains(["general", "hipaa", "pci_dss"], var.compliance_profile)
    error_message = "compliance_profile must be general, hipaa, or pci_dss."
  }
}
