###############################################################################
# Karpenter Helm Module — Variables
###############################################################################

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "controller_role_arn" {
  description = "Karpenter IRSA role ARN"
  type        = string
}

variable "interruption_queue_name" {
  description = "SQS queue name for interruption handling"
  type        = string
}

variable "node_role_name" {
  description = "Node role name (for instance profile mapping)"
  type        = string
}

variable "karpenter_version" {
  description = "Karpenter Helm chart version"
  type        = string
}
