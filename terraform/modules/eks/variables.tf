###############################################################################
# EKS Module — Input Variables (no defaults — all values from root)
###############################################################################

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB / control plane ENIs"
  type        = list(string)
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach EKS API (your IP)"
  type        = list(string)
}

variable "node_instance_types" {
  description = "Instance types for bootstrap node group"
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired number of bootstrap nodes"
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
  description = "AMI type for node group (AL2_x86_64 or AL2023_x86_64_STANDARD)"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
}
