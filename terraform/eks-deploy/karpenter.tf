###############################################################################
# Karpenter — IRSA module call (Phase 1 — pure AWS, no cluster needed)
###############################################################################

module "karpenter_irsa" {
  source = "../modules/karpenter-irsa"

  cluster_name              = var.cluster_name
  oidc_provider_arn         = module.eks.oidc_provider_arn
  oidc_provider_url         = module.eks.oidc_provider_url
  node_role_arn             = module.eks.node_role_arn
  karpenter_namespace       = var.karpenter_namespace
  karpenter_service_account = var.karpenter_service_account

  tags = local.common_tags
}
