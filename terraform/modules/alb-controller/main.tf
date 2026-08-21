###############################################################################
# ALB Controller Module — Helm install
#
# Note: This currently uses the node role for AWS permissions. In production
# you'd create a dedicated IRSA role with least-privilege ALB permissions.
# The --aws-region flag is required because AL2023 restricts IMDS access
# from pods, so the controller can't auto-detect its region.
###############################################################################

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.alb_controller_version

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  # IRSA supplies this controller pod with its own AWS credentials. Escaped
  # dots ensure Helm treats the annotation key as a literal key.
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.role_arn
  }

  wait    = true
  timeout = 300
}
