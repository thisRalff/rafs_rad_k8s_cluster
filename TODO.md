# GitOps POC - Running Task List

Project: EKS + Terraform + Helm + ArgoCD + Karpenter proof of concept.

## Done
- [x] `.gitignore` created (excludes aws_keys/, tfstate, tfvars, etc.)
- [x] VPC module (`terraform/modules/vpc/`) - public/private subnets across 2 AZs,
      single NAT gateway, EKS/Karpenter discovery tags baked in
- [x] `us-west-2` root module wired to VPC module, all values driven from variables.tf
      (no hardcoded literals in main.tf)
- [x] `terraform validate` passing on us-west-2 root module

## Not Doing (for now)
- VPC `apply` - skipped, module is validated, no need to stand it up yet
- AWS credential cleanup (plaintext key file) - deferred, keys expire soon anyway

## Done (cont.)
- [x] EKS module (`terraform/modules/eks/`) - control plane, cluster IAM role,
      node group IAM role, initial SPOT-based managed node group (t3.medium x2),
      IAM OIDC provider for IRSA (needed by Karpenter/ArgoCD service accounts later)
- [x] Wired EKS module into `us-west-2` root module, all values in variables.tf
- [x] `terraform validate` passing on full us-west-2 root module (vpc + eks)

## Done (cont.)
- [x] Split OIDC provider into its own module (`terraform/modules/oidc/`) -
      EKS module now just outputs `oidc_issuer_url`, root module wires it into
      the new oidc module
- [x] Local git repo initialized, pushed to GitHub (thisRalff/rafs_rad_k8s_cluster)
- [x] Karpenter IRSA module (`terraform/modules/karpenter-irsa/`) - controller
      IAM role with OIDC trust policy scoped to karpenter:karpenter service
      account, full EC2/IAM/EKS/SSM/Pricing permissions needed for node
      provisioning, plus SQS queue + EventBridge rules for spot interruption
      handling

## Next Up
- [ ] Commit + push the karpenter-irsa module
- [ ] Karpenter Helm install (after infra is applied) - pass controller_role_arn
      and interruption_queue_name from Terraform outputs into Helm values
- [ ] ArgoCD install (Helm)
- [ ] Demo app Helm chart (simple templated app - image tag/replica count/env values)
- [ ] Git repo for ArgoCD to sync from (app-of-apps or single app pattern)
- [ ] Demo scenarios to rehearse:
  - [ ] Manual `kubectl delete`/`edit` -> watch ArgoCD self-heal
  - [ ] Git commit (image tag bump) -> watch ArgoCD auto-sync
  - [ ] (stretch) Karpenter node scale-up under load, scale back down
  - [ ] (stretch) Argo Rollouts canary
