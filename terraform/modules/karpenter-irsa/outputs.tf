###############################################################################
# Karpenter IRSA Module — Outputs
###############################################################################

output "controller_role_arn" {
  description = "Karpenter controller IRSA role ARN (passed to Helm chart)"
  value       = aws_iam_role.karpenter_controller.arn
}

output "interruption_queue_name" {
  description = "SQS queue name for spot interruption handling (passed to Helm chart)"
  value       = aws_sqs_queue.karpenter_interruption.name
}

output "interruption_queue_arn" {
  description = "SQS queue ARN"
  value       = aws_sqs_queue.karpenter_interruption.arn
}
