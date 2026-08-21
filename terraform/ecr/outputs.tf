output "repository_url" {
  description = "ECR repository URL (use this in Helm values / docker push)"
  value       = aws_ecr_repository.wordpress.repository_url
}

output "repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.wordpress.arn
}
