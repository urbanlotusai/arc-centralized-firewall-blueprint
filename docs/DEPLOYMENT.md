# Deployment Guide

## Overview

This blueprint provisions a centralized hub-and-spoke network security architecture using AWS Network Firewall and Transit Gateway. All VPC traffic is inspected before being allowed to flow.

**Estimated apply time:** 20–30 minutes (Transit Gateway + Network Firewall provisioning)

---

## Prerequisites

### AWS Permissions Required

The deploying IAM principal needs:

```json
{
  "Effect": "Allow",
  "Action": [
    "kms:*",
    "s3:*",
    "ec2:*",                              
    "network-firewall:*",
    "route53:*",
    "ram:*",                              
    "logs:*"
  ],
  "Resource": "*"
}
```

The minimum viable policy should include `ec2:CreateTransitGateway`, `ec2:CreateVpcAttachment`, and `network-firewall:CreateFirewall`.

### Remote State Backend (recommended)

Add a backend block to `version.tf` before applying to shared environments:

```hcl
backend "s3" {
  bucket         = "<your-state-bucket>"
  key            = "centralized-firewall/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  kms_key_id     = "<your-state-kms-key>"
  dynamodb_table = "<your-lock-table>"
}
```

---

## Two-Apply Pattern (KMS)

The KMS key policy references `data.aws_caller_identity.current.account_id`. This is resolved at plan time, so a single `terraform apply` is sufficient. However, if the KMS key is pre-existing and passed in, run:

1. `terraform apply -target=module.kms` — create the CMK first
2. `terraform apply` — provision all remaining resources

---

## Apply Steps

```bash
# 1. Initialise with remote backend
terraform init

# 2. Review the plan
terraform plan -var-file=terraform.tfvars -out=tfplan

# 3. Apply
terraform apply tfplan
```

---

## Post-Apply Configuration

### 1. Update Spoke VPC Route Tables

After the TGW is provisioned, route spoke egress through it:

```bash
TGW_ID=$(terraform output -raw transit_gateway_id)

# For each spoke route table:
aws ec2 create-route \
  --route-table-id <spoke-rtb-id> \
  --destination-cidr-block 0.0.0.0/0 \
  --transit-gateway-id $TGW_ID
```

### 2. Verify Firewall Readiness

```bash
aws network-firewall describe-firewall \
  --firewall-arn $(terraform output -raw network_firewall_arn) \
  --query 'FirewallStatus.Status'
# Expected: "READY"
```

### 3. Check Log Delivery

Wait 5 minutes after first traffic, then:

```bash
BUCKET=$(terraform output -raw s3_log_bucket)
aws s3 ls s3://$BUCKET/network-firewall/alert/
aws s3 ls s3://$BUCKET/network-firewall/flow/
```

---

## Adding More Spoke VPCs

1. Add a new `module "transit_gateway_spoke_N"` block in `main.tf` with `create_transit_gateway = false` and the new spoke's VPC/subnet/route-table details.
2. Run `terraform plan` and `terraform apply`.
3. Update the new spoke's route tables to point to the TGW.

---

## Firewall Rule Updates

Blocked domains are managed via the `blocked_domains` variable. To add a new domain:

1. Add the domain to `terraform.tfvars`:
   ```hcl
   blocked_domains = ["malware.example.com", "newbadsite.example.org"]
   ```
2. Run `terraform apply` — the Suricata rule group is updated in-place (no downtime).

---

## Rollback

```bash
terraform destroy
```

Manual cleanup required:
1. Empty the S3 log bucket (`aws s3 rm s3://<bucket> --recursive`) before destroy if `force_destroy = false`.
2. Remove static routes from spoke route tables that pointed to the TGW before destroying it.
