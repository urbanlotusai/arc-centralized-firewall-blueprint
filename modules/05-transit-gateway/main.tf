# =============================================================================
# Module: 05-transit-gateway
# =============================================================================
# Provisions the Transit Gateway for hub-and-spoke routing. Attaches the hub
# VPC; spoke VPCs route through it to reach the firewall.
# State file: modules/05-transit-gateway/terraform.tfstate
# Depends on: 03-network (hub VPC)
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

data "aws_caller_identity" "current" {}

# Firewall subnets in the hub VPC — arc-network tags subnets by type
data "aws_subnets" "firewall" {
  filter {
    name   = "vpc-id"
    values = [data.terraform_remote_state.network.outputs.vpc_id]
  }
  tags = { Type = "private" }
}

# Hub VPC route tables — used by arc-transit-gateway to add TGW routes
data "aws_route_tables" "hub" {
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
}

# -----------------------------------------------------------------------------
# Transit Gateway Module
# -----------------------------------------------------------------------------

module "transit_gateway" {
  source  = "sourcefuse/arc-transit-gateway/aws"
  version = "0.0.1"

  transit_gateway_name   = "${var.namespace}-${var.environment}-${var.tgw_name}"
  create_transit_gateway = true

  # Hub VPC attachment
  target_vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
  target_subnet_ids      = data.aws_subnets.firewall.ids
  target_route_table_ids = data.aws_route_tables.hub.ids
  target_account_id      = [data.aws_caller_identity.current.account_id]

  # Spoke VPC attachment (first spoke; add more via separate module blocks)
  source_vpc_id     = var.spoke_vpc_id
  source_subnet_ids = var.spoke_subnet_ids
  source_cidr_block = var.spoke_cidr

  tags = var.tags
}
