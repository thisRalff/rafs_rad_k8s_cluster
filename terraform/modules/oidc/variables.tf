variable "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL from the EKS cluster (aws_eks_cluster.identity[0].oidc[0].issuer)"
  type        = string
}

variable "tags" {
  description = "Common tags applied to the OIDC provider"
  type        = map(string)
  default     = {}
}
