###############################################################################
# EKS Module — Outputs
###############################################################################

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.eks_telp_web.name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = aws_eks_cluster.eks_telp_web.endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64)"
  value       = aws_eks_cluster.eks_telp_web.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN (for IRSA trust policies)"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "OIDC issuer URL (without https://, for IAM conditions)"
  value       = replace(aws_eks_cluster.eks_telp_web.identity[0].oidc[0].issuer, "https://", "")
}

output "node_role_arn" {
  description = "Node IAM role ARN"
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "Node IAM role name"
  value       = aws_iam_role.node.name
}
