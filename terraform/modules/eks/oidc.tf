###############################################################################
# EKS Module — OIDC Provider (enables IRSA)
###############################################################################

# Fetch TLS cert from the cluster's OIDC issuer URL (for IAM thumbprint)
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks_telp_web.identity[0].oidc[0].issuer
}

# Register the cluster as a trusted identity provider with AWS IAM
resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.eks_telp_web.identity[0].oidc[0].issuer

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  tags = merge(var.tags, { Name = "${var.cluster_name}-oidc" })
}
