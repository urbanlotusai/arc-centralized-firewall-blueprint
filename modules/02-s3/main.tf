module "s3_logs" {
  source  = "sourcefuse/arc-s3/aws"
  version = "0.0.7"

  name      = var.name
  namespace = var.namespace

  sse_algorithm      = "aws:kms"
  kms_master_key_id  = var.kms_master_key_id
  versioning_enabled = true
  force_destroy      = false

  lifecycle_configuration_rules = var.lifecycle_configuration_rules

  tags = var.tags
}
