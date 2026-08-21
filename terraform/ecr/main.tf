###############################################################################
# ECR Repository — persistent container registry
#
# This stack is independent of the EKS cluster. It stays up permanently
# (costs pennies for storage) so images persist across cluster destroy/rebuild.
###############################################################################

resource "aws_ecr_repository" "wordpress" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE" # Allows overwriting tags (e.g. "latest")
  force_delete         = true      # Allow terraform destroy even if images exist

  image_scanning_configuration {
    scan_on_push = true # Scans for vulnerabilities on every push
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Lifecycle policy — keep last 10 images, auto-delete older ones
resource "aws_ecr_lifecycle_policy" "wordpress" {
  repository = aws_ecr_repository.wordpress.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
