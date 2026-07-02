# Getting Started

This guide walks you through deploying the **ARC Centralized Network Firewall Blueprint** from scratch.

## What you'll build

```
Spoke VPC(s) ──── Transit Gateway ──── Hub (Inspection) VPC
                                              ↓
                                    AWS Network Firewall
                                    (stateful Suricata rules)
                                              ↓
                                    S3 Log Bucket (KMS-encrypted)
```

All inter-VPC traffic flows through the AWS Network Firewall before reaching the internet or crossing spoke boundaries.

## Prerequisites

| Requirement | Minimum version |
|---|---|
| Terraform | 1.3.0 |
| AWS CLI | 2.x |
| AWS account | — |
| IAM permissions | See [docs/INSTALL.md](docs/INSTALL.md) |

You will also need the **VPC ID, subnet IDs, and route table IDs** of each spoke VPC you want to attach to the Transit Gateway.

## Step 1 — Clone and configure

```bash
git clone https://github.com/sourcefuse/arc-centralized-firewall-blueprint.git
cd arc-centralized-firewall-blueprint
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` — at minimum set:

```hcl
namespace   = "myorg"
environment = "prod"

spoke_vpc_id          = "vpc-0abc123def456789"
spoke_subnet_ids      = ["subnet-aaa", "subnet-bbb"]
spoke_route_table_ids = ["rtb-ccc", "rtb-ddd"]
spoke_account_ids     = ["123456789012"]
```

## Step 2 — Initialise

```bash
make init
# or: terraform init -backend=false
```

## Step 3 — Validate

```bash
make validate
# or: terraform init -backend=false && terraform validate
```

## Step 4 — Review the plan

```bash
make plan
```

Review the output carefully before applying. Key resources:
- `aws_kms_key` — CMK for log encryption
- `aws_networkfirewall_firewall` — the inspection engine
- `aws_ec2_transit_gateway` — the routing hub

## Step 5 — Apply

```bash
make apply
# or: terraform apply
```

The first apply takes approximately 15–25 minutes due to Transit Gateway propagation and Network Firewall provisioning.

## Step 6 — Update spoke route tables

After apply, update each spoke VPC's route tables to send traffic through the Transit Gateway:

```bash
# Example — add a default route in the spoke VPC pointing to the TGW
aws ec2 create-route \
  --route-table-id <spoke-rtb-id> \
  --destination-cidr-block 0.0.0.0/0 \
  --transit-gateway-id <tgw-id from outputs>
```

Replace `<spoke-rtb-id>` and `<tgw-id>` with values from `terraform output`.

## Step 7 — Verify firewall logs

```bash
aws s3 ls s3://<s3_log_bucket from output>/network-firewall/
```

You should see `alert/` and `flow/` prefixes appearing within minutes of traffic traversing the firewall.

## Cleaning up

```bash
terraform destroy
```

Note: empty the S3 log bucket manually first if `force_destroy = false`.
