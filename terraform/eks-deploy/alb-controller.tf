###############################################################################
# AWS Load Balancer Controller — IRSA identity (Stack 1, before Helm install)
###############################################################################

module "alb_controller_irsa" {
  source = "../modules/alb-controller-irsa"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  tags = local.common_tags
}
