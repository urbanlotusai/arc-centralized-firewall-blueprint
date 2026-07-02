# =============================================================================
# Module: 04-network-firewall
# =============================================================================
# Provisions AWS Network Firewall (stateful + stateless inspection) in the
# hub VPC, plus the stateful Suricata rule group used to block known-bad
# domains. All spoke traffic is routed through this inspection point.
# State file: modules/04-network-firewall/terraform.tfstate
# Depends on: 03-network (hub VPC), 02-s3 (log bucket)
# =============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.state_bucket_name
    key    = "modules/03-network/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "s3" {
  backend = "s3"

  config = {
    bucket = var.state_bucket_name
    key    = "modules/02-s3/terraform.tfstate"
    region = var.region
  }
}

# Firewall subnets in the hub VPC — arc-network tags subnets by type
data "aws_subnets" "firewall" {
  filter {
    name   = "vpc-id"
    values = [data.terraform_remote_state.network.outputs.vpc_id]
  }
  tags = { Type = "private" }
}

# -----------------------------------------------------------------------------
# Network Firewall Module
# -----------------------------------------------------------------------------

module "network_firewall" {
  source  = "sourcefuse/arc-network-firewall/aws"
  version = "0.0.3"

  name       = local.firewall_name
  vpc_id     = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = data.aws_subnets.firewall.ids

  firewall_policy_config = {
    create = true
    name   = "${local.firewall_name}-policy"

    stateless_default_actions          = ["aws:forward_to_sfe"]
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
          bucketName = data.terraform_remote_state.s3.outputs.bucket_id
          prefix     = "${local.firewall_log_prefix}/alert"
        }
      },
      {
        log_type             = "FLOW"
        log_destination_type = "S3"
        log_destination = {
          bucketName = data.terraform_remote_state.s3.outputs.bucket_id
          prefix     = "${local.firewall_log_prefix}/flow"
        }
      }
    ]
  }

  tags = var.tags
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

  tags = var.tags
}
