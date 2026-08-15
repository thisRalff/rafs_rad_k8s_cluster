variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "node_role_name" {
  description = "Name of the IAM role for Karpenter-provisioned nodes"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where Karpenter can launch nodes"
  type        = list(string)
}

variable "instance_categories" {
  description = "EC2 instance categories Karpenter can use"
  type        = list(string)
  default     = ["t", "m", "c"]
}

variable "instance_sizes" {
  description = "EC2 instance sizes Karpenter can use"
  type        = list(string)
  default     = ["medium", "large", "xlarge"]
}

variable "capacity_types" {
  description = "Capacity types (on-demand, spot) Karpenter can use"
  type        = list(string)
  default     = ["spot", "on-demand"]
}

variable "cpu_limit" {
  description = "Maximum total CPU cores Karpenter can provision"
  type        = number
  default     = 100
}
