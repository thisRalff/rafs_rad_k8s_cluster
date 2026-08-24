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
        # Network access is enforced solely by this operator SG (single source
        # of truth). Custom SGs disable the controller's auto-managed frontend
        # SG, so we let it still manage backend rules to reach the pods.
        alb.ingress.kubernetes.io/security-groups: ${aws_security_group.operator_alb.id}
        alb.ingress.kubernetes.io/manage-backend-security-group-rules: "true"
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
