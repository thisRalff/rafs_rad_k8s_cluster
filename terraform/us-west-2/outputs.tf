output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  value = module.oidc.provider_arn
}

output "eks_oidc_provider_url" {
  value = module.oidc.provider_url
}

output "karpenter_controller_role_arn" {
  value = module.karpenter_irsa.controller_role_arn
}

output "karpenter_interruption_queue_name" {
  value = module.karpenter_irsa.interruption_queue_name
}
