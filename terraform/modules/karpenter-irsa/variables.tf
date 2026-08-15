variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider (from the oidc module)"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider without https:// prefix"
  type        = string
}

variable "karpenter_namespace" {
  description = "Kubernetes namespace where Karpenter will be installed"
  type        = string
  default     = "karpenter"
}

variable "karpenter_service_account" {
  description = "Name of the Kubernetes service account for Karpenter"
  type        = string
  default     = "karpenter"
}

variable "node_role_arn" {
  description = "ARN of the IAM role used by Karpenter-provisioned nodes"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
