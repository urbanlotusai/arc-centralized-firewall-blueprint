module "route53" {
  source  = "sourcefuse/arc-route53/aws"
  version = "0.0.1"

  vpc_id = var.vpc_id

  tags = var.tags
}
