# ArgoCD Helm release - installs the ArgoCD GitOps controller into the cluster

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = var.argocd_namespace
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_version
  wait             = true
  timeout          = 600

  # Expose the server UI via LoadBalancer for easy demo access
  set {
    name  = "server.service.type"
    value = var.server_service_type
  }

  # Disable TLS on the server for POC simplicity (no cert management needed)
  set {
    name  = "configs.params.server\\.insecure"
    value = tostring(var.server_insecure)
  }

  # Disable Dex (SSO) - not needed for a POC
  set {
    name  = "dex.enabled"
    value = "false"
  }

  # Disable notifications - not needed for a POC
  set {
    name  = "notifications.enabled"
    value = "false"
  }
}
