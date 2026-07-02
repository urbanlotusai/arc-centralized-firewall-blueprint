# Examples

## general.tfvars

Standard hub-and-spoke deployment with one spoke VPC. Suitable for most environments.

```bash
cp general.tfvars ../terraform.tfvars
cd ..
make validate && make plan
```

## Adding a second spoke VPC

To attach additional spoke VPCs, add a second module block in `main.tf`:

```hcl
module "transit_gateway_spoke_b" {
  source  = "sourcefuse/arc-transit-gateway/aws"
  version = "0.0.1"

  transit_gateway_name   = local.tgw_name
  create_transit_gateway = false  # re-use existing TGW

  target_vpc_id          = module.network.vpc_id
  target_subnet_ids      = data.aws_subnets.firewall.ids
  target_route_table_ids = [module.network.vpc_id]
  target_account_id      = [data.aws_caller_identity.current.account_id]

  source_vpc_id     = "<spoke-b-vpc-id>"
  source_subnet_ids = ["<subnet-1>", "<subnet-2>"]
  source_cidr_block = "10.1.0.0/16"

  tags = local.tags
}
```

Then update the spoke-b route tables to route through the TGW.
