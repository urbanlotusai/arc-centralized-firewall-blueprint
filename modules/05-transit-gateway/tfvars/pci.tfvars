# =============================================================================
# 05-transit-gateway - PCI-DSS Compliance Profile
# =============================================================================
# No profile-specific overrides — this module has no compliance-differentiated
# variables beyond the universal namespace/environment/region/tags/
# state_bucket_name. Replace the spoke placeholders with your actual spoke
# VPC details before applying.
# =============================================================================

tgw_name         = "hub-transit-gateway"
spoke_vpc_id     = "vpc-0abc123def456789"
spoke_subnet_ids = ["subnet-0aaa111bbb222ccc3", "subnet-0ddd444eee555fff6"]
spoke_cidr       = "10.0.0.0/8"
