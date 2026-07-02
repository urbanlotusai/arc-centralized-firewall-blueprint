# =============================================================================
# 02-s3 - HIPAA Compliance Profile
# =============================================================================
# Compliance controls enabled:
#   - log_retention_days = 365 — supports HIPAA's audit-log retention
#     expectations (45 CFR 164.316(b)(2)(i)) for firewall alert/flow logs
#     that may reference PHI-adjacent network activity.
# =============================================================================

log_retention_days = 365
