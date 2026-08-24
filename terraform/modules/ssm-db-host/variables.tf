###############################################################################
# ssm-db-host module — inputs
#
# Publishes ONLY the restored (temporary) DB host to SSM, alongside the
# existing production params. The container reuses the existing
# /todoelpaso/db/{name,user,password} and /todoelpaso/wp/* values, since the
# restored DB is a copy of prod and shares those credentials.
###############################################################################

variable "parameter_name" {
  description = "SSM parameter name for the temp/k8s DB host"
  type        = string
  default     = "/todoelpaso/db/host_k8s"
}

variable "db_host" {
  description = "Restored DB hostname to publish"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
