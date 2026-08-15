output "controller_role_arn" {
  description = "ARN of the Karpenter controller IAM role (pass to Helm)"
  value       = aws_iam_role.karpenter_controller.arn
}

output "controller_role_name" {
  description = "Name of the Karpenter controller IAM role"
  value       = aws_iam_role.karpenter_controller.name
}

output "interruption_queue_name" {
  description = "Name of the SQS queue for spot interruption events"
  value       = aws_sqs_queue.karpenter_interruption.name
}
