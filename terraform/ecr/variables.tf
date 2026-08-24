variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "allowed_account_ids" {
  description = "AWS account IDs this stack may apply against (guard). Set in ignored tfvars."
  type        = list(string)
}

variable "repository_name" {
  description = "ECR repository name"
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
