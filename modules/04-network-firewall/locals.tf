locals {
  firewall_name       = "${var.namespace}-${var.environment}-anfw"
  firewall_log_prefix = "network-firewall"

  # Blocked domain rule group Suricata rule string
  blocked_domain_rules = join("\n", [
    for domain in var.blocked_domains :
    "drop tls any any -> any any (tls.sni; content:\"${domain}\"; nocase; endswith; msg:\"Block ${domain}\"; sid:${index(var.blocked_domains, domain) + 1000001}; rev:1;)"
  ])
}
