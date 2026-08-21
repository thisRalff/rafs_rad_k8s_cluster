###############################################################################
# AWS Load Balancer Controller IRSA Module — Input Variables
###############################################################################

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN used by the EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL without https://, used in IAM trust conditions"
  type        = string
}

variable "namespace" {
  description = "Namespace containing the controller ServiceAccount"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "ServiceAccount used by the AWS Load Balancer Controller"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
}
