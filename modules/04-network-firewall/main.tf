module "network_firewall" {
  source  = "sourcefuse/arc-network-firewall/aws"
  version = "0.0.3"

  name       = var.name
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  firewall_policy_config = var.firewall_policy_config

  logging_config = var.logging_config

  tags = var.tags
}
