variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  type        = string
}

variable "karpenter_namespace" {
  description = "Kubernetes namespace for Karpenter"
  type        = string
  default     = "karpenter"
}

variable "karpenter_version" {
  description = "Version of the Karpenter Helm chart"
  type        = string
  default     = "1.0.8"
}

variable "controller_role_arn" {
  description = "ARN of the IAM role for the Karpenter controller (from karpenter-irsa module)"
  type        = string
}

variable "interruption_queue_name" {
  description = "Name of the SQS queue for spot interruption events"
  type        = string
}

variable "node_role_name" {
  description = "Name of the IAM role for Karpenter-provisioned nodes"
  type        = string
}
