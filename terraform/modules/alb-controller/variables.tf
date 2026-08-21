###############################################################################
# ALB Controller Module — Variables
###############################################################################

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region (passed explicitly to the controller pod)"
  type        = string
}

variable "alb_controller_version" {
  description = "AWS LB Controller Helm chart version"
  type        = string
}

variable "role_arn" {
  description = "Dedicated IRSA role ARN for the controller ServiceAccount"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
}
