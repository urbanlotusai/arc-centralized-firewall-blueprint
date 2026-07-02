# ─────────────────────────────────────────────────────────────────────────────
# ARC Centralized Network Firewall Blueprint — Makefile
# ─────────────────────────────────────────────────────────────────────────────
VERSION := $(shell cat VERSION)

.DEFAULT_GOAL := help

.PHONY: help fmt init validate plan apply clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

fmt: ## Format all Terraform files
	terraform fmt -recursive

init: ## Initialise (no backend — local validation only)
	terraform init -backend=false

validate: init ## Validate the configuration
	terraform validate

plan: ## Show an execution plan (requires terraform.tfvars + AWS creds)
	terraform plan

apply: ## Apply the configuration (requires terraform.tfvars + AWS creds)
	terraform apply

clean: ## Remove local Terraform state and build artifacts
	rm -rf .terraform .terraform.lock.hcl tfplan *.tfplan
