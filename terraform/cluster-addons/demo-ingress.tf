###############################################################################
# Restricted Hello World ingress — smoke-tests ALB Controller and pod routing.
#
# The operator CIDR is supplied only through ignored terraform.tfvars. Argo CD
# owns the demo Deployments/Service; Terraform owns this external entry point.
###############################################################################

resource "kubectl_manifest" "demo_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: demo
      labels:
        app.kubernetes.io/managed-by: terraform
  YAML
}

resource "kubectl_manifest" "demo_app_ingress" {
  yaml_body = <<-YAML
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: demo-app
      namespace: demo
      labels:
        app: demo-app
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
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: demo-app
                    port:
                      number: 80
  YAML

  depends_on = [
    module.alb_controller,
    kubectl_manifest.demo_namespace,
  ]
}
