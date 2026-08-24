###############################################################################
# Cluster Addons — Module Calls
#
# Stack 2: installs cluster tooling via Helm.
# Requires Stack 1 (wordpress-eks) to be applied first.
###############################################################################

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "karpenter_helm" {
  source = "../modules/karpenter-helm"

  cluster_name            = var.cluster_name
  cluster_endpoint        = var.cluster_endpoint
  controller_role_arn     = var.karpenter_controller_role_arn
  interruption_queue_name = var.karpenter_interruption_queue_name
  node_role_name          = var.karpenter_node_role_name
  karpenter_version       = var.karpenter_version
}

module "karpenter_nodepool" {
  source = "../modules/karpenter-nodepool"

  cluster_name       = var.cluster_name
  node_role_name     = var.karpenter_node_role_name
  private_subnet_ids = var.private_subnet_ids

  depends_on = [module.karpenter_helm]
}

module "alb_controller" {
  source = "../modules/alb-controller"

  cluster_name           = var.cluster_name
  vpc_id                 = var.vpc_id
  aws_region             = var.aws_region
  alb_controller_version = var.alb_controller_version
  role_arn               = var.alb_controller_role_arn

  tags = local.common_tags
}

module "argocd" {
  source = "../modules/argocd"

  argocd_version = var.argocd_version
}

module "external_secrets" {
  source = "../modules/external-secrets"

  chart_version = var.eso_chart_version
  role_arn      = var.eso_role_arn
}

module "rds_restore" {
  source = "../modules/rds-restore"

  identifier                       = var.rds_restore_identifier
  snapshot_identifier              = var.rds_restore_snapshot_id
  instance_class                   = var.rds_restore_instance_class
  db_subnet_group_name             = var.rds_restore_subnet_group_name
  vpc_id                           = var.vpc_id
  allowed_source_security_group_id = var.cluster_security_group_id

  tags = local.common_tags
}

# Publish ONLY the restored DB host to SSM (/todoelpaso/db/host_k8s). Reuses the
# existing prod db name/user/password + wp salts, since this DB is a copy.
module "ssm_db_host" {
  source = "../modules/ssm-db-host"

  db_host = module.rds_restore.address

  tags = local.common_tags
}
