# =============================================================================
# Module: 06-route53
# =============================================================================
# Provisions a Route53 private hosted zone associated with the hub VPC,
# enabling spoke VPCs to resolve private hosted zones through the hub.
# State file: modules/06-route53/terraform.tfstate
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

# -----------------------------------------------------------------------------
# Route53 Module
# -----------------------------------------------------------------------------

module "route53" {
  source  = "sourcefuse/arc-route53/aws"
  version = "0.0.1"

  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  tags = var.tags
}
