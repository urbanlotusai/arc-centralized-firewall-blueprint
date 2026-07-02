# =============================================================================
# Module: 03-network
# =============================================================================
# Provisions the hub (inspection) VPC. The hub VPC hosts the Network
# Firewall and the Transit Gateway attachment; spoke VPCs route through
# the TGW -> hub -> firewall -> internet.
# State file: modules/03-network/terraform.tfstate
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
# Network Module
# -----------------------------------------------------------------------------

module "network" {
  source  = "sourcefuse/arc-network/aws"
  version = "3.0.14"

  name        = "${var.namespace}-${var.environment}-hub"
  namespace   = var.namespace
  environment = var.environment
  cidr_block  = var.cidr_block

  tags = var.tags
}
