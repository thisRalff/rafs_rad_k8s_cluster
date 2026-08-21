###############################################################################
# Karpenter IRSA Module — Input Variables (no defaults — all values from root)
###############################################################################

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN (from EKS module)"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL without https:// (from EKS module)"
  type        = string
}

variable "node_role_arn" {
  description = "Node IAM role ARN — Karpenter needs iam:PassRole to assign it to new nodes"
  type        = string
}

variable "karpenter_namespace" {
  description = "Namespace where Karpenter runs"
  type        = string
}

variable "karpenter_service_account" {
  description = "ServiceAccount name Karpenter uses (must match Helm chart)"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
}
