###############################################################################
# Variables — all actual values live in terraform.tfvars (gitignored)
###############################################################################

# --- General ---
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name — used in tags, IAM roles, kubectl context"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment label (e.g. learning, dev, production)"
  type        = string
}

# --- Existing VPC ---
variable "vpc_id" {
  description = "Existing VPC ID to deploy EKS into (data source, never modified)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Existing private subnet IDs — where worker nodes and pods run"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Existing public subnet IDs — where ALB Ingress is placed"
  type        = list(string)
}

# --- Existing External Services ---
variable "rds_endpoint" {
  description = "RDS endpoint (host:port) — pods connect here for the database"
  type        = string
}

variable "rds_security_group_id" {
  description = "RDS security group — we'll add an ingress rule from the pod SG"
  type        = string
}

variable "redis_endpoint" {
  description = "ElastiCache Redis endpoint (host:port)"
  type        = string
}

variable "redis_security_group_id" {
  description = "Redis security group — we'll add an ingress rule from the pod SG"
  type        = string
}

# --- Access Control ---
variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the EKS public API endpoint (your IP)"
  type        = list(string)
}

# --- EKS Configuration ---
variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "node_instance_types" {
  description = "Instance types for bootstrap node group"
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired bootstrap node count"
  type        = number
}

variable "node_min_size" {
  description = "Minimum bootstrap nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum bootstrap nodes"
  type        = number
}

variable "node_ami_type" {
  description = "AMI type for node group (AL2023_x86_64_STANDARD for k8s 1.30+)"
  type        = string
}

# --- Karpenter ---
variable "karpenter_namespace" {
  description = "Namespace where Karpenter controller runs"
  type        = string
}

variable "karpenter_service_account" {
  description = "Karpenter ServiceAccount name (must match Helm chart)"
  type        = string
}
