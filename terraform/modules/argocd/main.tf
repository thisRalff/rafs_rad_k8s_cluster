###############################################################################
# ArgoCD Module — Helm install
###############################################################################

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_version
  wait             = true
  timeout          = 600

  # Expose ArgoCD server via ClusterIP (access via port-forward for now)
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # Disable TLS on the ArgoCD server (ALB terminates/handles the edge)
  set {
    name  = "configs.params.server\\.insecure"
    value = "true"
  }

  # Served under the /argocd subpath on the shared operator ALB. rootpath alone
  # makes the server serve its UI, assets, and redirects under that prefix;
  # setting basehref as well would double the prefix (/argocd/argocd).
  set {
    name  = "configs.params.server\\.rootpath"
    value = "/argocd"
  }

  # Disable Dex (SSO) — not needed for this project
  set {
    name  = "dex.enabled"
    value = "false"
  }

  # Disable notifications — not needed for this project
  set {
    name  = "notifications.enabled"
    value = "false"
  }
}
