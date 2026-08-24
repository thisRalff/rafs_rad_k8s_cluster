###############################################################################
# rds-restore module — outputs
###############################################################################

output "endpoint" {
  description = "Restored DB endpoint (host:port)"
  value       = aws_db_instance.restore.endpoint
}

output "address" {
  description = "Restored DB hostname"
  value       = aws_db_instance.restore.address
}

output "port" {
  description = "Restored DB port"
  value       = aws_db_instance.restore.port
}

output "security_group_id" {
  description = "Security group protecting the restored DB"
  value       = aws_security_group.db.id
}

output "identifier" {
  description = "Restored DB instance identifier"
  value       = aws_db_instance.restore.identifier
}
