module "transit_gateway" {
  source  = "sourcefuse/arc-transit-gateway/aws"
  version = "0.0.1"

  transit_gateway_name   = var.transit_gateway_name
  create_transit_gateway = true

  # Hub VPC attachment
  target_vpc_id          = var.target_vpc_id
  target_subnet_ids      = var.target_subnet_ids
  target_route_table_ids = var.target_route_table_ids
  target_account_id      = var.target_account_id

  # Spoke VPC attachment (first spoke; add more via separate module blocks)
  source_vpc_id     = var.source_vpc_id
  source_subnet_ids = var.source_subnet_ids
  source_cidr_block = var.source_cidr_block

  tags = var.tags
}
