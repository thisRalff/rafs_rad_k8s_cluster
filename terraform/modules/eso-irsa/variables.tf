###############################################################################
# External Secrets Operator IRSA Module — Input Variables
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
  description = "Namespace containing the ESO ServiceAccount"
  type        = string
  default     = "external-secrets"
}

variable "service_account_name" {
  description = "ServiceAccount used by External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "ssm_parameter_arns" {
  description = "SSM parameter ARNs ESO may read"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS region (for SSM ARN scoping)"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
}
