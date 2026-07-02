<div align="center">

# ARC Centralized Network Firewall Blueprint

### Hub-and-spoke network with AWS Network Firewall — in one `terraform apply`

**A SourceFuse ARC Blueprint**

![Version](https://img.shields.io/badge/version-1.0.0-E8392A)
![License](https://img.shields.io/badge/license-Apache--2.0-1A1A2E)
![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.3-7B42BC)
![AWS Provider](https://img.shields.io/badge/aws--provider-%3E%3D5.0-FF9900)
![ARC Modules](https://img.shields.io/badge/ARC%20modules-6-E8392A)

</div>

---

## What is this?

A **ready-to-deploy Terraform blueprint** that provisions a centralized hub-and-spoke network
security architecture on AWS using **6 [SourceFuse ARC](https://registry.terraform.io/namespaces/modules/sourcefuse)
modules**. One `terraform apply` gives you:

- A **Hub (inspection) VPC** where all cross-VPC and internet-bound traffic is inspected
- **AWS Network Firewall** with stateful Suricata rules for domain blocking and IPS
- **Transit Gateway** to attach spoke VPCs and route traffic through the hub
- **KMS CMK** encrypting all firewall alert and flow logs
- **S3 log bucket** (KMS-encrypted) with configurable retention
- **Route53 private hosted zone** for centralized DNS resolution across all VPCs

No hand-wiring of Transit Gateway route tables, firewall policy attachments, or S3 log delivery permissions. The hard, error-prone parts are already solved and pinned.

---

## Why use this blueprint?

| Advantage | What it means for you |
|---|---|
| ⚡ **Minutes, not days** | A production hub-and-spoke with Network Firewall normally takes days of networking Terraform — this deploys in one command. |
| 🔒 **Secure by default** | All firewall alert and flow logs are KMS-encrypted at rest. Spoke VPCs cannot communicate directly — all traffic flows through the inspection point. |
| 🧱 **Defense in depth** | Stateless rules for quick allow/deny + stateful Suricata rules for domain blocking, IPS signatures, and TLS SNI inspection. |
| 📋 **Domain blocklist as code** | Pass a list of blocked domains in `terraform.tfvars` — Suricata IPS rules are auto-generated. No manual rule editing. |
| 📊 **Full traffic visibility** | Alert logs (blocked/suspicious) and flow logs (all traffic) go to S3. Query with Athena or feed your SIEM. |
| 📦 **Portable & auditable** | Pure Terraform. Version-controlled, reproducible across environments and accounts. |
| 🛠️ **Beginner-friendly** | One `Makefile`, copy-paste example tfvars, and step-by-step docs for macOS, Linux, and Windows. |

---

## Architecture

```
  Spoke VPC A ──┐
  Spoke VPC B ──┼──► Transit Gateway (arc-transit-gateway)
  Spoke VPC C ──┘            │
                              ▼
                   Hub (Inspection) VPC (arc-network)
                              │
                              ▼
                    AWS Network Firewall (arc-network-firewall)
                    ├── Stateless: pass/drop/forward-to-SFE
                    └── Stateful (Suricata): domain blocking, IPS
                              │
                              ▼
                    S3 Log Bucket (arc-s3, KMS-encrypted)
                    ├── alert/   ← blocked + suspicious flows
                    └── flow/    ← all traffic flows

                    Route53 Private Zone (arc-route53)
                    └── centralized DNS for spoke resolution
```

All spoke VPC egress and cross-spoke traffic flows through the firewall. Spokes never route directly to each other or the internet.

---

## The 6 ARC modules

| Module | Version | Role |
|---|---|---|
| [arc-kms](https://registry.terraform.io/modules/sourcefuse/arc-kms/aws) | 1.0.11 | Customer Managed Key — encrypts all firewall logs |
| [arc-s3](https://registry.terraform.io/modules/sourcefuse/arc-s3/aws) | 0.0.7 | KMS-encrypted firewall log bucket (alert + flow) |
| [arc-network](https://registry.terraform.io/modules/sourcefuse/arc-network/aws) | 3.0.14 | Hub (inspection) VPC with firewall subnets |
| [arc-network-firewall](https://registry.terraform.io/modules/sourcefuse/arc-network-firewall/aws) | 0.0.3 | AWS Network Firewall + stateful/stateless policy |
| [arc-transit-gateway](https://registry.terraform.io/modules/sourcefuse/arc-transit-gateway/aws) | 0.0.1 | Transit Gateway for hub-and-spoke routing |
| [arc-route53](https://registry.terraform.io/modules/sourcefuse/arc-route53/aws) | 0.0.1 | Centralized private DNS resolution |

---

## Quick start

### 1. Prerequisites

- **Terraform** `>= 1.3` ([install guide](docs/INSTALL.md))
- **AWS credentials** configured (`aws configure`)
- **VPC ID, subnet IDs, and route table IDs** of each spoke VPC to attach

### 2. Configure

```bash
git clone https://github.com/sourcefuse/arc-centralized-firewall-blueprint.git
cd arc-centralized-firewall-blueprint

cp examples/general.tfvars terraform.tfvars
```

Edit the mandatory values in `terraform.tfvars`:

| Variable | Example |
|---|---|
| `environment` | `prod` |
| `namespace` | `myorg` |
| `spoke_vpc_id` | `vpc-0abc123def456789` |
| `spoke_subnet_ids` | `["subnet-aaa", "subnet-bbb"]` |
| `spoke_route_table_ids` | `["rtb-ccc", "rtb-ddd"]` |
| `spoke_account_ids` | `["123456789012"]` |

### 3. Deploy

| Step | With `make` | Raw Terraform (all OS) |
|---|---|---|
| Validate | `make validate` | `terraform init -backend=false && terraform validate` |
| Preview | `make plan` | `terraform plan` |
| Deploy | `make apply` | `terraform init && terraform apply` |

> ⏱️ Allow 20–30 minutes for Transit Gateway propagation and Network Firewall provisioning.

### 4. Update spoke route tables

After apply, route spoke egress through the Transit Gateway:

```bash
TGW_ID=$(terraform output -raw transit_gateway_id)

aws ec2 create-route \
  --route-table-id <spoke-rtb-id> \
  --destination-cidr-block 0.0.0.0/0 \
  --transit-gateway-id $TGW_ID
```

### 5. Verify firewall logs

```bash
aws s3 ls s3://$(terraform output -raw s3_log_bucket)/network-firewall/
# You should see alert/ and flow/ prefixes appearing within minutes of traffic
```

---

## Key outputs

```bash
terraform output hub_vpc_id              # hub (inspection) VPC ID
terraform output network_firewall_arn    # AWS Network Firewall ARN
terraform output firewall_policy_arn     # firewall policy ARN
terraform output transit_gateway_id      # TGW ID — add to spoke route tables
terraform output transit_gateway_arn     # TGW ARN
terraform output s3_log_bucket           # S3 bucket name for firewall logs
terraform output s3_log_bucket_arn       # S3 bucket ARN
terraform output route53_zone_id         # private hosted zone ID
terraform output kms_key_arn             # CMK ARN
```

---

## Project structure

```
arc-centralized-firewall-blueprint/
├── main.tf                   # 6 ARC module blocks + Suricata rule group resource
├── variables.tf              # all inputs with types & descriptions
├── locals.tf                 # naming, tags, Suricata rule string generation
├── data.tf                   # caller identity, KMS policy, subnet lookups
├── outputs.tf                # firewall ARN, TGW ID, S3 bucket, KMS ARN
├── version.tf                # Terraform + AWS provider pins
├── terraform.tfvars.example  # copy to terraform.tfvars
├── examples/
│   ├── README.md
│   └── general.tfvars
├── docs/
│   ├── INSTALL.md            # macOS · Linux · Windows setup guide
│   └── DEPLOYMENT.md        # full deployment + spoke attachment + rule updates
├── GETTING-STARTED.md        # beginner walkthrough
├── CONTRIBUTING.md
├── CHANGELOG.md · LICENSE · NOTICE · Makefile · VERSION
└── README.md
```

---

## Documentation

- **[GETTING-STARTED.md](GETTING-STARTED.md)** — zero-to-live walkthrough for first-timers
- **[docs/INSTALL.md](docs/INSTALL.md)** — install Terraform & AWS CLI on macOS / Linux / Windows
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** — full deployment, spoke attachment, rule updates, rollback
- **[examples/README.md](examples/README.md)** — example tfvars and adding more spoke VPCs

---

## Important notes

- **Spoke route tables are NOT updated by Terraform** — after apply, you must manually add a `0.0.0.0/0 → transit-gateway-id` route in each spoke VPC's route tables. This is intentional to avoid unintended traffic disruption.
- **Network Firewall takes ~15 minutes to become READY** — `aws network-firewall describe-firewall --firewall-arn <arn> --query 'FirewallStatus.Status'` should return `"READY"` before routing live traffic through it.
- **Adding more spokes** — add additional `module "transit_gateway_spoke_N"` blocks with `create_transit_gateway = false` and the new spoke's VPC details. See [examples/README.md](examples/README.md).
- **Blocked domain list** — updating `blocked_domains` in `terraform.tfvars` and re-running `terraform apply` updates the Suricata rule group in-place with no firewall downtime.
- **Empty the S3 bucket before destroy** — if `force_destroy = false` (default), you must run `aws s3 rm s3://<bucket> --recursive` before `terraform destroy`.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE).

---

<div align="center">

### Built by [SourceFuse](https://www.sourcefuse.com)

Part of the **ARC** (Accelerated Reference Cloud) blueprint family.
Explore all ARC modules on the [Terraform Registry](https://registry.terraform.io/namespaces/modules/sourcefuse).

</div>
