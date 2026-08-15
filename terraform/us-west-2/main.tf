locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = var.managed_by
  }
}

module "vpc" {
  source = "../modules/vpc"

  name         = var.project_name
  cluster_name = var.cluster_name
  azs          = var.azs

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway

  tags = local.common_tags
}

module "eks" {
  source = "../modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  endpoint_public_access  = var.endpoint_public_access
  endpoint_private_access = var.endpoint_private_access
  public_access_cidrs     = var.public_access_cidrs

  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_capacity_type  = var.node_capacity_type

  tags = local.common_tags
}

module "oidc" {
  source = "../modules/oidc"

  cluster_oidc_issuer_url = module.eks.oidc_issuer_url

  tags = local.common_tags
}

module "karpenter_irsa" {
  source = "../modules/karpenter-irsa"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.oidc.provider_arn
  oidc_provider_url = module.oidc.provider_url
  node_role_arn     = module.eks.node_role_arn

  tags = local.common_tags
}

module "karpenter_helm" {
  source = "../modules/karpenter-helm"

  cluster_name            = var.cluster_name
  cluster_endpoint        = module.eks.cluster_endpoint
  controller_role_arn     = module.karpenter_irsa.controller_role_arn
  interruption_queue_name = module.karpenter_irsa.interruption_queue_name
  node_role_name          = module.eks.node_role_name

  depends_on = [module.eks]
}

module "karpenter_nodepool" {
  source = "../modules/karpenter-nodepool"

  cluster_name       = var.cluster_name
  node_role_name     = module.eks.node_role_name
  private_subnet_ids = module.vpc.private_subnet_ids

  depends_on = [module.karpenter_helm]
}

module "argocd" {
  source = "../modules/argocd"

  argocd_namespace    = var.argocd_namespace
  argocd_version      = var.argocd_version
  server_service_type = var.argocd_service_type

  depends_on = [module.eks]
}
