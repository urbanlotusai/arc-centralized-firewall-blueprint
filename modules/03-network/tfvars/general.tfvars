# =============================================================================
# 03-network - General Compliance Profile
# =============================================================================
# No profile-specific overrides — this module has no compliance-differentiated
# variables beyond the universal namespace/environment/region/tags/
# state_bucket_name. The hub VPC uses RFC 6598 (CGNAT) address space to avoid
# colliding with spoke VPC CIDRs.
# =============================================================================

cidr_block = "100.64.0.0/16"
