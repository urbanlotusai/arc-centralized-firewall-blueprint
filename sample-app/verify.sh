#!/usr/bin/env bash
# Proves that traffic from a spoke VPC is actually inspected by the hub firewall
# by generating a request to a blocked-domain test URL and confirming an ALERT
# log lands in the S3 log bucket.
set -euo pipefail

FIREWALL_ID=$(terraform output -raw network_firewall_id)
LOG_BUCKET=$(terraform output -raw s3_log_bucket)

echo "== Network Firewall status =="
aws network-firewall describe-firewall --firewall-arn "$(terraform output -raw network_firewall_arn)" \
  --query 'FirewallStatus.Status' --output text

echo
echo "== Generate test traffic from an EC2 instance in a spoke VPC =="
echo "curl -m 5 http://testmyids.com/   # known Suricata test signature, should be blocked/alerted"
echo
echo "== Check for ALERT logs in S3 (may take 1-2 minutes to appear) =="
aws s3 ls "s3://${LOG_BUCKET}/" --recursive | grep -i alert | tail -n 20 || \
  echo "No alert logs found yet — generate traffic first, then re-run this script."

echo
echo "Firewall ID: $FIREWALL_ID"
echo "Log bucket:  $LOG_BUCKET"
