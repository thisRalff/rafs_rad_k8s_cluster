###############################################################################
# ssm-db-host module — outputs
###############################################################################

output "parameter_name" {
  description = "SSM parameter name holding the temp DB host"
  value       = aws_ssm_parameter.db_host_k8s.name
}

output "parameter_arn" {
  description = "ARN of the SSM parameter"
  value       = aws_ssm_parameter.db_host_k8s.arn
}
