variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the cluster and nodes will run in"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for worker nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (needed for control plane ENI placement / public endpoint access)"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API endpoint is enabled"
  type        = bool
}

variable "endpoint_private_access" {
  description = "Whether the EKS private API endpoint is enabled"
  type        = bool
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to access the EKS public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "Instance types for the initial managed node group"
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired number of nodes in the initial managed node group"
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of nodes in the initial managed node group"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of nodes in the initial managed node group"
  type        = number
}

variable "node_capacity_type" {
  description = "Capacity type for the initial managed node group (ON_DEMAND or SPOT)"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
