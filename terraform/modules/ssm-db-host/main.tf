###############################################################################
# ssm-db-host module
#
# Writes the restored (temporary) DB host to SSM Parameter Store so the ECR
# WordPress container can read its DB endpoint the same way it reads the other
# /todoelpaso/db/* values. Terraform owns this parameter, so `terraform
# destroy` removes it automatically when the temp DB is torn down.
#
# NOTE: this deliberately does NOT touch the production /todoelpaso/db/host.
###############################################################################

resource "aws_ssm_parameter" "db_host_k8s" {
  name        = var.parameter_name
  description = "Temporary k8s WordPress DB host (restored copy of prod). Managed by Terraform; removed on destroy."
  type        = "String"
  value       = var.db_host

  tags = merge(var.tags, { Name = var.parameter_name })
}
