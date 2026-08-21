###############################################################################
# Karpenter NodePool Module — Variables
###############################################################################

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "node_role_name" {
  description = "Node IAM role name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for node placement"
  type        = list(string)
}
