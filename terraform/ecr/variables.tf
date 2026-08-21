variable "aws_region" {
  description = "AWS region"
  type        = string
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
