# ═══════════════════════════════════════════════════════════════════════════════
# 1. KMS — encryption for firewall logs and S3 bucket
#    Outputs consumed by: module.s3, module.network_firewall
# ═══════════════════════════════════════════════════════════════════════════════
module "kms" {
  source  = "sourcefuse/arc-kms/aws"
  version = "1.0.11"

  alias                   = local.kms_alias
  policy                  = data.aws_iam_policy_document.kms.json
  description             = "CMK for ${local.name_prefix} Centralized Network Firewall"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  tags = local.tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 2. S3 — centralized log bucket for firewall alert / flow / TLS logs
#    Outputs consumed by: module.network_firewall (logging_config)
# ═══════════════════════════════════════════════════════════════════════════════
module "s3_logs" {
  source  = "sourcefuse/arc-s3/aws"
  version = "0.0.7"

  name      = local.s3_log_bucket_name
  namespace = var.namespace

  sse_algorithm         = "aws:kms"
  kms_master_key_id     = module.kms.key_arn
  versioning_enabled    = true
  force_destroy         = false

  lifecycle_configuration_rules = [
    {
      id      = "ExpireOldLogs"
      enabled = true
      expiration = {
        days = local.log_retention_days
      }
    }
  ]

  tags = local.tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 3. Network — Hub (inspection) VPC
#    The hub VPC hosts the Network Firewall and the Transit Gateway attachment.
#    Spoke VPCs route through the TGW → hub → firewall → internet.
#    Outputs consumed by: module.network_firewall, module.transit_gateway
# ═══════════════════════════════════════════════════════════════════════════════
module "network" {
  source  = "sourcefuse/arc-network/aws"
  version = "3.0.14"

  name        = local.hub_vpc_name
  namespace   = var.namespace
  environment = var.environment
  cidr_block  = var.hub_vpc_cidr

  tags = local.tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 4. Network Firewall — stateful + stateless inspection in the hub VPC
#    All spoke traffic is routed through this inspection point.
# ═══════════════════════════════════════════════════════════════════════════════
module "network_firewall" {
  source  = "sourcefuse/arc-network-firewall/aws"
  version = "0.0.3"

  name       = local.firewall_name
  vpc_id     = module.network.vpc_id
  subnet_ids = data.aws_subnets.firewall.ids

  firewall_policy_config = {
    create = true
    name   = "${local.firewall_name}-policy"

    stateless_default_actions         = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_references = [
      {
        resource_arn = aws_networkfirewall_rule_group.blocked_domains.arn
        priority     = 1
      }
    ]
  }

  logging_config = {
    enable = true
    log_destination_configs = [
      {
        log_type             = "ALERT"
        log_destination_type = "S3"
        log_destination = {
          bucketName = module.s3_logs.bucket_id
          prefix     = "${local.firewall_log_prefix}/alert"
        }
      },
      {
        log_type             = "FLOW"
        log_destination_type = "S3"
        log_destination = {
          bucketName = module.s3_logs.bucket_id
          prefix     = "${local.firewall_log_prefix}/flow"
        }
      }
    ]
  }

  tags = local.tags

  depends_on = [module.network, module.s3_logs]
}

# Stateful rule group — block known-bad domains (Suricata IPS rules)
resource "aws_networkfirewall_rule_group" "blocked_domains" {
  name     = "${local.firewall_name}-blocked-domains"
  type     = "STATEFUL"
  capacity = 100

  rule_group {
    rules_source {
      rules_string = local.blocked_domain_rules
    }
  }

  tags = local.tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 5. Transit Gateway — hub-and-spoke routing
#    Attaches the hub VPC; spoke VPCs route through it to reach the firewall.
#    arc-transit-gateway requires the *hub* VPC details as target_vpc_id.
# ═══════════════════════════════════════════════════════════════════════════════
module "transit_gateway" {
  source  = "sourcefuse/arc-transit-gateway/aws"
  version = "0.0.1"

  transit_gateway_name  = local.tgw_name
  create_transit_gateway = true

  # Hub VPC attachment
  target_vpc_id          = module.network.vpc_id
  target_subnet_ids      = data.aws_subnets.firewall.ids
  target_route_table_ids = data.aws_route_tables.hub.ids
  target_account_id      = [data.aws_caller_identity.current.account_id]

  # Spoke VPC attachment (first spoke; add more via separate module blocks)
  source_vpc_id       = var.spoke_vpc_id
  source_subnet_ids   = var.spoke_subnet_ids
  source_cidr_block   = var.spoke_cidr

  tags = local.tags

  depends_on = [module.network]
}

# ═══════════════════════════════════════════════════════════════════════════════
# 6. Route53 — centralized DNS resolution via the hub VPC
#    Enables spoke VPCs to resolve private hosted zones through the hub.
# ═══════════════════════════════════════════════════════════════════════════════
module "route53" {
  source  = "sourcefuse/arc-route53/aws"
  version = "0.0.1"

  vpc_id = module.network.vpc_id

  tags = local.tags

  depends_on = [module.network]
}
