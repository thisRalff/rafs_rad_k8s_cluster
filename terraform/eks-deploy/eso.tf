###############################################################################
# External Secrets Operator — IRSA identity (Stack 1, before ESO Helm install)
#
# Scoped to read only /todoelpaso/* SSM params and decrypt them via the SSM
# KMS key. The ESO Helm release (Stack 2) annotates its ServiceAccount with
# this role ARN.
###############################################################################

module "eso_irsa" {
  source = "../modules/eso-irsa"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  aws_region        = var.aws_region

  ssm_parameter_arns = [
    "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/todoelpaso/*",
  ]

  tags = local.common_tags
}
