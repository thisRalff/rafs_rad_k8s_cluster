###############################################################################
# Cluster Addons — Variables (all values from tfvars)
###############################################################################

# --- General ---
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment label"
  type        = string
}

# --- Cluster Connection (from Stack 1 outputs) ---
variable "cluster_endpoint" {
  description = "EKS API server endpoint"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "EKS cluster CA certificate (base64)"
  type        = string
}

# --- Karpenter ---
variable "karpenter_controller_role_arn" {
  description = "Karpenter IRSA role ARN (from Stack 1)"
  type        = string
}

variable "karpenter_interruption_queue_name" {
  description = "SQS queue name for spot interruption (from Stack 1)"
  type        = string
}

variable "karpenter_node_role_name" {
  description = "Node IAM role name (Karpenter assigns this to nodes it launches)"
  type        = string
}

variable "karpenter_version" {
  description = "Karpenter Helm chart version"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs (for Karpenter EC2NodeClass)"
  type        = list(string)
}

# --- ALB Controller ---
variable "alb_controller_version" {
  description = "AWS LB Controller Helm chart version"
  type        = string
}

variable "alb_controller_role_arn" {
  description = "Dedicated AWS Load Balancer Controller IRSA role ARN from Stack 1"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (ALB Controller needs this)"
  type        = string
}

# --- ArgoCD ---
variable "argocd_version" {
  description = "ArgoCD Helm chart version"
  type        = string
}

# --- External Secrets Operator ---
variable "eso_chart_version" {
  description = "external-secrets Helm chart version"
  type        = string
}

variable "eso_role_arn" {
  description = "ESO IRSA role ARN from Stack 1"
  type        = string
}

# --- Operator access (Argo CD UI ingress) ---
variable "operator_allowed_cidrs" {
  description = "CIDR blocks allowed to reach the operator ALB listener (Argo CD UI)"
  type        = list(string)
}

# --- RDS restore (isolated copy of prod DB for the cluster) ---
variable "cluster_security_group_id" {
  description = "EKS cluster security group ID (from Stack 1 output); source SG for DB access"
  type        = string
}

variable "rds_restore_snapshot_id" {
  description = "Manual snapshot of the production DB to restore from"
  type        = string
}

variable "rds_restore_identifier" {
  description = "Identifier for the restored DB instance"
  type        = string
  default     = "telp-k8s-wp-restore"
}

variable "rds_restore_instance_class" {
  description = "Instance class for the restored DB (mirror source)"
  type        = string
  default     = "db.t4g.small"
}

variable "rds_restore_subnet_group_name" {
  description = "DB subnet group for the restored instance"
  type        = string
}
