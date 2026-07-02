# =============================================================================
# Module: 02-s3
# =============================================================================
# Provisions the S3 bucket that receives centralized Network Firewall alert
# and flow logs.
# State file: modules/02-s3/terraform.tfstate
# Depends on: 01-kms (encryption key)
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

data "terraform_remote_state" "kms" {
  backend = "s3"

  config = {
    bucket = var.state_bucket_name
    key    = "modules/01-kms/terraform.tfstate"
    region = var.region
  }
}

# -----------------------------------------------------------------------------
# S3 Module
# -----------------------------------------------------------------------------

module "s3_logs" {
  source  = "sourcefuse/arc-s3/aws"
  version = "0.0.7"

  name      = "${var.namespace}-${var.environment}-firewall-logs"
  namespace = var.namespace

  sse_algorithm      = "aws:kms"
  kms_master_key_id  = data.terraform_remote_state.kms.outputs.key_arn
  versioning_enabled = true
  force_destroy      = false

  lifecycle_configuration_rules = [
    {
      id      = "ExpireOldLogs"
      enabled = true
      expiration = {
        days = var.log_retention_days
      }
    }
  ]

  tags = var.tags
}
