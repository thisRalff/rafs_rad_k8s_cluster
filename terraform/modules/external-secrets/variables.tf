###############################################################################
# External Secrets Operator (Helm) — Variables
###############################################################################

variable "chart_version" {
  description = "external-secrets Helm chart version"
  type        = string
}

variable "role_arn" {
  description = "IRSA role ARN for the ESO ServiceAccount (SSM read + KMS decrypt)"
  type        = string
}

variable "namespace" {
  description = "Namespace for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "service_account_name" {
  description = "ServiceAccount name for ESO"
  type        = string
  default     = "external-secrets"
}
