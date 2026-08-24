###############################################################################
# External Secrets Operator IRSA Module — Outputs
###############################################################################

output "role_arn" {
  description = "Dedicated IRSA role ARN for External Secrets Operator"
  value       = aws_iam_role.eso.arn
}
