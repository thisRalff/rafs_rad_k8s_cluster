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
- [x] Local git repo initialized (`git init`), terraform/ + .gitignore + TODO.md
      staged (resumes and aws_keys/ left untracked/ignored) - not committed yet,
      only commit when explicitly asked

## Next Up
- [ ] First commit (waiting on explicit go-ahead)
- [ ] Decide on remote (GitHub, given job spec leans GitHub Actions) and repo
      structure (single repo vs separate app-source/gitops-config repos)
- [ ] IRSA IAM roles for Karpenter specifically (controller role + node role,
      trust policy scoped to the OIDC provider)
- [ ] Karpenter install (Helm) - pointed at private subnets already tagged
      `karpenter.sh/discovery`
- [ ] ArgoCD install (Helm)
- [ ] Demo app Helm chart (simple templated app - image tag/replica count/env values)
- [ ] Git repo for ArgoCD to sync from (app-of-apps or single app pattern)
- [ ] Demo scenarios to rehearse:
  - [ ] Manual `kubectl delete`/`edit` -> watch ArgoCD self-heal
  - [ ] Git commit (image tag bump) -> watch ArgoCD auto-sync
  - [ ] (stretch) Karpenter node scale-up under load, scale back down
  - [ ] (stretch) Argo Rollouts canary
