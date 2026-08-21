###############################################################################
# AWS Load Balancer Controller IRSA Module — Outputs
###############################################################################

output "role_arn" {
  description = "Dedicated IRSA role ARN for the AWS Load Balancer Controller"
  value       = aws_iam_role.controller.arn
}
