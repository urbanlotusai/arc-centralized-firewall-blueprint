# Sample App

A **verification script** proving spoke-VPC traffic is actually routed through the hub inspection firewall — no application code needed for a network security blueprint.

```
Spoke VPC instance → Transit Gateway → Hub VPC → Network Firewall → S3 alert/flow logs
```

---

## Verify the firewall is inspecting traffic

```bash
export AWS_REGION=<your-region>
./sample-app/verify.sh
```

The script:
1. Confirms the Network Firewall status is `READY`
2. Prints a test command to run from an EC2 instance in an attached spoke VPC (`curl http://testmyids.com/` — a known Suricata test signature)
3. Checks the S3 log bucket for `ALERT` log entries confirming the firewall inspected and flagged the traffic

## Manual test from a spoke instance

```bash
# From an EC2 instance in a VPC attached via the Transit Gateway:
curl -m 5 http://testmyids.com/
```

Within 1-2 minutes, an alert log should appear at:
```
s3://$(terraform output -raw s3_log_bucket)/<firewall_log_prefix>/alert/...
```

## Order of operations

1. `terraform apply` — creates KMS, S3 log bucket, hub VPC, Network Firewall, Transit Gateway, Route53
2. Attach a spoke VPC (set `spoke_vpc_id`, `spoke_subnet_ids`, `spoke_cidr` in `terraform.tfvars`)
3. Update spoke VPC route tables to send `0.0.0.0/0` through the Transit Gateway
4. Run `verify.sh` and generate test traffic from a spoke instance
5. Confirm `ALERT` logs appear in the S3 bucket

---

Built by **[SourceFuse](https://www.sourcefuse.com)**.
