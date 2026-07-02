# =============================================================================
# Module: 01-kms
# =============================================================================
# Provisions the customer-managed KMS key used to encrypt Network Firewall
# alert/flow logs and the S3 log bucket in this blueprint.
# State file: modules/01-kms/terraform.tfstate
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

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms" {
  statement {
    sid    = "AllowAccountRoot"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Network Firewall log delivery requires kms:GenerateDataKey/Decrypt/DescribeKey
  statement {
    sid    = "AllowNetworkFirewallLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com", "network-firewall.amazonaws.com"]
    }
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }

  # S3 server-side encryption of the firewall log bucket
  statement {
    sid    = "AllowS3SSE"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
    resources = ["*"]
  }
}

# -----------------------------------------------------------------------------
# KMS Module
# -----------------------------------------------------------------------------

module "kms" {
  source  = "sourcefuse/arc-kms/aws"
  version = "1.0.11"

  alias                   = "alias/${var.namespace}-${var.environment}-firewall"
  policy                  = data.aws_iam_policy_document.kms.json
  description             = "CMK for ${var.namespace}-${var.environment} Centralized Network Firewall"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true

  tags = var.tags
}
