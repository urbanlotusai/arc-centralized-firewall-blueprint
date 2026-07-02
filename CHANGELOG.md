# Changelog

All notable changes to this project are documented here.
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] – 2026-07-02

### Added
- Initial release: ARC Centralized Network Firewall (Hub-Spoke) Blueprint
- Hub VPC (arc-network 3.0.14) with dedicated inspection subnets
- AWS Network Firewall (arc-network-firewall 0.0.3) with stateful domain-blocking rules
- Transit Gateway (arc-transit-gateway 0.0.1) for hub-and-spoke routing
- KMS CMK (arc-kms 1.0.11) encrypting all firewall logs
- S3 log bucket (arc-s3 0.0.7) with lifecycle expiration and SSE-KMS
- Route53 private hosted zone (arc-route53 0.0.1) for centralized DNS resolution
- Configurable blocked-domain list → auto-generated Suricata IPS rules
- Firewall alert + flow logs routed to S3
- `terraform.tfvars.example` with spoke VPC attachment parameters
