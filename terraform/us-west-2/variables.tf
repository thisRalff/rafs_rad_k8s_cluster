variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Short name used as a prefix for resources"
  type        = string
  default     = "gitops-poc"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "gitops-poc"
}

variable "azs" {
  description = "Availability zones for the VPC (2 minimum for EKS)"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ"
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ"
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets instead of one per AZ (cheaper, less HA - fine for a POC)"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment tag value"
  type        = string
  default     = "poc"
}

variable "managed_by" {
  description = "ManagedBy tag value"
  type        = string
  default     = "terraform"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.31"
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether the EKS private API endpoint is enabled"
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "Instance types for the initial managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of nodes in the initial managed node group"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes in the initial managed node group"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes in the initial managed node group"
  type        = number
  default     = 3
}

variable "node_capacity_type" {
  description = "Capacity type for the initial managed node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}
