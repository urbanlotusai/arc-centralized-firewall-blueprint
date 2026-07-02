locals {
  name_prefix = "${var.namespace}-${var.environment}"

  tags = {
    Namespace         = var.namespace
    Environment       = var.environment
    ManagedBy         = "Terraform"
    Blueprint         = "centralized-firewall"
    ComplianceProfile = var.compliance_profile
  }

  # Compliance overlay
  is_hipaa           = var.compliance_profile == "hipaa"
  is_pci_dss         = var.compliance_profile == "pci_dss"
  is_strict          = local.is_hipaa || local.is_pci_dss
  log_retention_days = local.is_strict ? 365 : var.log_retention_days

  # Resource names (consistent suffix pattern)
  kms_alias             = "alias/${local.name_prefix}-firewall"
  hub_vpc_name          = "${local.name_prefix}-hub"
  firewall_name         = "${local.name_prefix}-anfw"
  tgw_name              = "${local.name_prefix}-${var.tgw_name}"
  s3_log_bucket_name    = "${local.name_prefix}-firewall-logs"
  firewall_log_prefix   = "network-firewall"

  # Blocked domain rule group Suricata rule string
  blocked_domain_rules = join("\n", [
    for domain in var.blocked_domains :
    "drop tls any any -> any any (tls.sni; content:\"${domain}\"; nocase; endswith; msg:\"Block ${domain}\"; sid:${index(var.blocked_domains, domain) + 1000001}; rev:1;)"
  ])
}
