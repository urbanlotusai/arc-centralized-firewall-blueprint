# ── Profile: hipaa ────────────────────────────────────────────────────────────
# Activates the HIPAA overlay:
#   - S3 firewall log retention extended to 365 days

namespace   = "sf"
environment = "prod"

region = "us-east-1"

compliance_profile = "hipaa"

hub_vpc_cidr = "100.64.0.0/16"

spoke_vpc_id          = "vpc-0abc123def456789"
spoke_subnet_ids      = ["subnet-0aaa111bbb222ccc3", "subnet-0ddd444eee555fff6"]
spoke_route_table_ids = ["rtb-0ggg777hhh888iii9", "rtb-0jjj000kkk111lll2"]
spoke_account_ids     = ["123456789012"]
spoke_cidr            = "10.0.0.0/8"

tgw_name = "hub-transit-gateway"

blocked_domains = [
  "malware.example.com",
  "badactor.example.net",
]

# HIPAA: enforce 365-day log retention
log_retention_days  = 365
kms_deletion_window = 30
