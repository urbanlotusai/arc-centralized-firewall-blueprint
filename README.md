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
| **Minutes, not days** | A production hub-and-spoke with Network Firewall normally takes days of networking Terraform — this deploys in one command. |
| **Secure by default** | All firewall alert and flow logs are KMS-encrypted at rest. Spoke VPCs cannot communicate directly — all traffic flows through the inspection point. |
| **Defense in depth** | Stateless rules for quick allow/deny + stateful Suricata rules for domain blocking, IPS signatures, and TLS SNI inspection. |
| **Domain blocklist as code** | Pass a list of blocked domains in `modules/04-network-firewall/tfvars/<profile>.tfvars` — Suricata IPS rules are auto-generated. No manual rule editing. |
| **Full traffic visibility** | Alert logs (blocked/suspicious) and flow logs (all traffic) go to S3. Query with Athena or feed your SIEM. |
| **Portable & auditable** | Pure Terraform. Version-controlled, reproducible across environments and accounts. |
| **Beginner-friendly** | One `Makefile`, copy-paste example tfvars, and step-by-step docs for macOS, Linux, and Windows. |

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

### 2. Clone

```bash
git clone https://github.com/urbanlotusai/arc-centralized-firewall-blueprint.git
cd arc-centralized-firewall-blueprint
```

This blueprint uses **independent per-module Terraform state** — there is no root `main.tf`. Each `modules/NN-name/` is applied on its own, with cross-module values (like the hub VPC ID and log bucket name) resolved via `terraform_remote_state` data sources rather than a parent module.

### 3. Bootstrap the state backend (once per environment)

```bash
make bootstrap ENV=dev REGION=us-east-1 NAMESPACE=myorg
```

Creates the S3 state bucket + DynamoDB lock table every module's backend uses.

### 4. Deploy all modules

```bash
make apply ENV=dev REGION=us-east-1 NAMESPACE=myorg
```

This runs `terraform init` + `apply` across `modules/01-kms` through `modules/06-route53` in order. The `spoke_vpc_id` and `spoke_subnet_ids` variables default to placeholder values — either edit `modules/05-transit-gateway/tfvars/general.tfvars` or pass `-var` overrides with your actual spoke VPC details.

### Deploy a single module with a compliance profile

```bash
./scripts/apply-module.sh 04-network-firewall dev us-east-1 hipaa
```

Copies `modules/04-network-firewall/tfvars/hipaa.tfvars` → `terraform.tfvars` for that module, then inits/plans/applies it alone.

| Step | With `make` (all modules) | Single module |
|---|---|---|
| Validate | `make validate` | `cd modules/<NN-name> && terraform validate` |
| Preview | `make plan` | `./scripts/apply-module.sh <name> <env> <region> <profile>` then inspect the plan |
| Deploy | `make apply` | `./scripts/apply-module.sh <name> <env> <region> <profile>` |

> ⏱ Allow 20–30 minutes for Transit Gateway propagation and Network Firewall provisioning.

### 5. Update spoke route tables

After apply, route spoke egress through the Transit Gateway:

```bash
TGW_ID=$(terraform output -raw transit_gateway_id)

aws ec2 create-route \
  --route-table-id <spoke-rtb-id> \
  --destination-cidr-block 0.0.0.0/0 \
  --transit-gateway-id $TGW_ID
```

### 6. Verify firewall logs

```bash
aws s3 ls s3://$(cd modules/02-s3 && terraform output -raw bucket_id)/network-firewall/
# You should see alert/ and flow/ prefixes appearing within minutes of traffic
```

---

## Key outputs

Each module's outputs live in its own state — run `terraform output` from inside that `modules/NN-name/` directory:

```bash
cd modules/03-network            && terraform output vpc_id             # hub (inspection) VPC ID
cd modules/04-network-firewall    && terraform output arn                # AWS Network Firewall ARN
cd modules/04-network-firewall    && terraform output policy_arn         # firewall policy ARN
cd modules/05-transit-gateway     && terraform output transit_gateway_id # TGW ID — add to spoke route tables
cd modules/05-transit-gateway     && terraform output transit_gateway_arn
cd modules/02-s3                  && terraform output bucket_id          # S3 bucket name for firewall logs
cd modules/02-s3                  && terraform output bucket_arn
cd modules/06-route53             && terraform output zone_id            # private hosted zone ID
cd modules/01-kms                 && terraform output key_arn            # CMK ARN
```

---

## Compliance profiles

| Profile | Effect |
|---|---|
| `general` | KMS rotation on, 90-day S3 log retention |
| `hipaa` | 365-day S3 firewall log retention |
| `pci` | 365-day S3 firewall log retention |

Apply a profile to any module with `./scripts/apply-module.sh <module> <env> <region> <profile>`.

---

## Project structure

```
arc-centralized-firewall-blueprint/
├── bootstrap/                 # creates the S3 + DynamoDB state backend (apply first)
│   ├── main.tf · variables.tf · outputs.tf
├── modules/                   # each folder is an independent Terraform root
│   ├── 01-kms/
│   │   ├── config.hcl         # static backend key
│   │   ├── main.tf            # own backend "s3" {}, own provider, own module block
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── tfvars/{general,hipaa,pci}.tfvars
│   ├── 02-s3/
│   ├── 03-network/
│   ├── 04-network-firewall/    # also owns the Suricata blocked-domains rule group
│   ├── 05-transit-gateway/
│   └── 06-route53/
├── scripts/
│   └── apply-module.sh        # apply one module with a chosen compliance profile
├── Makefile                   # bootstrap / init / plan / apply / validate / fmt
├── .terraform-version         # tfenv pin (1.9.8)
├── sample-app/                # verify.sh proving inspection traffic flows through the firewall
├── docs/
│   ├── INSTALL.md             # macOS · Linux · Windows setup guide
│   └── DEPLOYMENT.md          # full deployment reference + rollback
├── GETTING-STARTED.md         # beginner walkthrough
├── CONTRIBUTING.md
├── CHANGELOG.md · LICENSE · NOTICE · VERSION
└── README.md
```

---

## Documentation

- **[GETTING-STARTED.md](GETTING-STARTED.md)** — zero-to-live walkthrough for first-timers
- **[docs/INSTALL.md](docs/INSTALL.md)** — install Terraform & AWS CLI on macOS / Linux / Windows
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** — full deployment, spoke attachment, rule updates, rollback
- **`modules/*/tfvars/{general,hipaa,pci}.tfvars`** — per-module compliance-profile example files

---

## Important notes

- **Spoke route tables are NOT updated by Terraform** — after apply, you must manually add a `0.0.0.0/0 → transit-gateway-id` route in each spoke VPC's route tables. This is intentional to avoid unintended traffic disruption.
- **Network Firewall takes ~15 minutes to become READY** — `aws network-firewall describe-firewall --firewall-arn <arn> --query 'FirewallStatus.Status'` should return `"READY"` before routing live traffic through it.
- **Adding more spokes** — attach an additional spoke by adding a second `module "transit_gateway"`-style resource (or re-applying `modules/05-transit-gateway` with `create_transit_gateway = false`) pointed at the new spoke's VPC details.
- **Blocked domain list** — updating `blocked_domains` in `modules/04-network-firewall/tfvars/<profile>.tfvars` and re-applying that module updates the Suricata rule group in-place with no firewall downtime. The rule group resource now lives inside `modules/04-network-firewall/` (it was moved out of the old root `main.tf`, which no longer exists).
- **Empty the S3 bucket before destroy** — if `force_destroy = false` (default), you must run `aws s3 rm s3://<bucket> --recursive` before destroying `modules/02-s3`.

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
