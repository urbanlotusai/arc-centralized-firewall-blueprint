# =============================================================================
# 04-network-firewall - General Compliance Profile
# =============================================================================
# Domain blocking isn't compliance-tier-specific — the same blocklist applies
# across general/hipaa/pci. Replace with your actual malware/C2 domain list.
# =============================================================================

blocked_domains = [
  "malware.example.com",
  "badactor.example.net",
]
