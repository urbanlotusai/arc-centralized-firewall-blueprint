# ── General deployment — hub-and-spoke with one spoke VPC ──────────────────

namespace   = "sf"
environment = "prod"

region = "us-east-1"

# Hub VPC — dedicated inspection VPC (use RFC 6598 address space for the hub)
hub_vpc_cidr = "100.64.0.0/16"

# Spoke VPC — replace with your actual spoke VPC details
spoke_vpc_id          = "vpc-0abc123def456789"
spoke_subnet_ids      = ["subnet-0aaa111bbb222ccc3", "subnet-0ddd444eee555fff6"]
spoke_route_table_ids = ["rtb-0ggg777hhh888iii9", "rtb-0jjj000kkk111lll2"]
spoke_account_ids     = ["123456789012"]
spoke_cidr            = "10.0.0.0/8"

tgw_name = "hub-transit-gateway"

# Firewall
blocked_domains = [
  "malware.example.com",
  "badactor.example.net",
]

# Logging
log_retention_days  = 90
kms_deletion_window = 30
