output "namespace" {
  description = "Namespace where Karpenter is installed"
  value       = helm_release.karpenter.namespace
}

output "release_name" {
  description = "Name of the Helm release"
  value       = helm_release.karpenter.name
}
