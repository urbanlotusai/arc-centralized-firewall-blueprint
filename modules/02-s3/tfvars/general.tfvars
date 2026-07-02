# =============================================================================
# 02-s3 - General Compliance Profile
# =============================================================================
# Standard 90-day retention for firewall alert/flow logs — suitable for
# non-regulated workloads. Encryption is always on via the CMK from 01-kms
# regardless of profile.
# =============================================================================

log_retention_days = 90
