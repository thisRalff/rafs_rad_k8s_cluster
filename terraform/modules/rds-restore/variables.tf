###############################################################################
# rds-restore module — inputs
###############################################################################

variable "identifier" {
  description = "Identifier for the restored DB instance"
  type        = string
  default     = "telp-k8s-wp-restore"
}

variable "snapshot_identifier" {
  description = "Source manual snapshot to restore from (of the production DB)"
  type        = string
}

variable "instance_class" {
  description = "DB instance class (mirror source unless overridden)"
  type        = string
  default     = "db.t4g.small"
}

variable "db_subnet_group_name" {
  description = "DB subnet group to place the restored instance in"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the DB security group"
  type        = string
}

variable "allowed_source_security_group_id" {
  description = "Security group allowed to reach the DB on 3306 (EKS cluster/node SG)"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
