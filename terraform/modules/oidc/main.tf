# IAM OIDC provider for the EKS cluster - required for IRSA (IAM Roles for
# Service Accounts), so Karpenter, ArgoCD, and the LB controller can assume
# scoped IAM roles from within the cluster without static credentials.

data "tls_certificate" "cluster" {
  url = var.cluster_oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "cluster" {
  url             = var.cluster_oidc_issuer_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]

  tags = var.tags
}
