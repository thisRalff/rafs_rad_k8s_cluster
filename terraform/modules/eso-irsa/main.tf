###############################################################################
# External Secrets Operator IRSA Module
#
# Dedicated role for ESO. Trust is scoped to exactly the ESO ServiceAccount.
# Permissions: read the /todoelpaso/* SSM parameters and decrypt SecureString
# values with the AWS-managed SSM KMS key. ESO is the ONLY component that
# reads SSM; workloads consume the synced Kubernetes Secret.
###############################################################################

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eso" {
  name = "${var.cluster_name}-external-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
            "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, { Name = "${var.cluster_name}-external-secrets" })
}

resource "aws_iam_role_policy" "eso" {
  name = "${var.cluster_name}-external-secrets-ssm-read"
  role = aws_iam_role.eso.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadTodoelpasoParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
        ]
        Resource = var.ssm_parameter_arns
      },
      {
        Sid    = "DecryptSecureStringParameters"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
        ]
        # SecureString params use the AWS-managed SSM key (alias/aws/ssm).
        Resource = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${var.aws_region}.amazonaws.com"
          }
        }
      },
    ]
  })
}
