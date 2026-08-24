###############################################################################
# Outputs
###############################################################################

output "vpc_id" {
  description = "VPC ID (existing, read-only reference)"
  value       = data.aws_vpc.existing.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = data.aws_vpc.existing.cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs (tagged for EKS)"
  value       = var.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs (tagged for ALB)"
  value       = var.public_subnet_ids
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate (base64)"
  value       = module.eks.cluster_ca_certificate
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "alb_controller_role_arn" {
  description = "Dedicated AWS Load Balancer Controller IRSA role ARN"
  value       = module.alb_controller_irsa.role_arn
}

output "node_role_name" {
  description = "Node IAM role name"
  value       = module.eks.node_role_name
}

output "cluster_security_group_id" {
  description = "EKS-managed cluster security group (used by nodes/pods; source for RDS access)"
  value       = module.eks.cluster_security_group_id
}

output "eso_role_arn" {
  description = "External Secrets Operator IRSA role ARN"
  value       = module.eso_irsa.role_arn
}

output "karpenter_controller_role_arn" {
  description = "Karpenter IRSA role ARN"
  value       = module.karpenter_irsa.controller_role_arn
}

output "karpenter_interruption_queue_name" {
  description = "Karpenter SQS interruption queue name"
  value       = module.karpenter_irsa.interruption_queue_name
}
