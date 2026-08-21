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
