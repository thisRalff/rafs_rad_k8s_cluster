variable "argocd_namespace" {
  description = "Kubernetes namespace to install ArgoCD into"
  type        = string
  default     = "argocd"
}

variable "argocd_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.7.7"
}

variable "server_service_type" {
  description = "Service type for ArgoCD server (ClusterIP, LoadBalancer, NodePort)"
  type        = string
  default     = "LoadBalancer"
}

variable "server_insecure" {
  description = "Run ArgoCD server without TLS (simplifies POC access)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
