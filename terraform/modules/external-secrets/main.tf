###############################################################################
# External Secrets Operator — Helm install
#
# Installs ESO and its CRDs. The controller ServiceAccount is annotated with
# the dedicated IRSA role so ESO can read /todoelpaso/* from SSM and sync it
# into Kubernetes Secrets that workloads consume.
###############################################################################

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.chart_version
  wait             = true
  timeout          = 600

  # Install CRDs (SecretStore, ExternalSecret, etc.)
  set {
    name  = "installCRDs"
    value = "true"
  }

  # Use a named ServiceAccount and attach the IRSA role.
  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.role_arn
  }
}
