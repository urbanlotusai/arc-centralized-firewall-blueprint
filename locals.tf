locals {
  name_prefix = "${var.namespace}-${var.environment}"

  tags = {
    Namespace   = var.namespace
    Environment = var.environment
    ManagedBy   = "Terraform"
    Blueprint   = "centralized-firewall"
  }

  # Compliance overlay — drives tighter settings when any strict profile is active
  is_strict = false # set to true for compliance hardening (no profile var for this blueprint)

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
