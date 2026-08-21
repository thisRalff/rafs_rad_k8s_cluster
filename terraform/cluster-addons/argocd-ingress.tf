###############################################################################
# Restricted Argo CD UI ingress — operator-only access via ALB.
#
# The operator CIDR is supplied only through ignored terraform.tfvars.
# Argo CD server runs with --insecure (HTTP on port 80 behind ClusterIP),
# so the ALB terminates nothing; this is HTTP-only, restricted to operator IP.
###############################################################################

resource "kubectl_manifest" "argocd_ingress" {
  yaml_body = <<-YAML
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: argocd-server
      namespace: argocd
      labels:
        app.kubernetes.io/managed-by: terraform
      annotations:
        alb.ingress.kubernetes.io/group.name: telp-operator
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
        alb.ingress.kubernetes.io/inbound-cidrs: ${join(",", var.operator_allowed_cidrs)}
    spec:
      ingressClassName: alb
      rules:
        - http:
            paths:
              - path: /argocd
                pathType: Prefix
                backend:
                  service:
                    name: argocd-server
                    port:
                      number: 80
  YAML

  depends_on = [
    module.alb_controller,
    module.argocd,
  ]
}
