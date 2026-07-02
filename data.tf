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

# Firewall subnets in the hub VPC — arc-network tags subnets by type
data "aws_subnets" "firewall" {
  filter {
    name   = "vpc-id"
    values = [module.network.vpc_id]
  }
  tags       = { Type = "private" }
  depends_on = [module.network]
}

# Hub VPC route tables — used by arc-transit-gateway to add TGW routes
data "aws_route_tables" "hub" {
  vpc_id     = module.network.vpc_id
  depends_on = [module.network]
}
