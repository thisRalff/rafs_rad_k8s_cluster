output "namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = var.argocd_namespace
}

output "server_service_name" {
  description = "Name of the ArgoCD server service (for getting the LB URL)"
  value       = "argocd-server"
}
