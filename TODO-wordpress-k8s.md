# WordPress on K8s — Full Build TODO

## Goal
Run todoelpaso.com on EKS behind ALB with Nginx+PHP-FPM pods, managed via
Helm + ArgoCD. Spin up / destroy at will. Learn every layer.

---

## Phase 1: Infrastructure (Terraform)

Two stacks: `eks-deploy` (platform) and `cluster-addons` (tooling).

### Stack 1: eks-deploy (platform)

- [x] **1.1 — VPC Tagging** (reusing existing production VPC)
  - Tagged private subnets: `kubernetes.io/role/internal-elb`, `karpenter.sh/discovery`
  - Tagged public subnets: `kubernetes.io/role/elb`
  - Tagged both: `kubernetes.io/cluster/telp-k8s = shared`
  - Data source for VPC (read-only, cannot destroy existing infra)

- [x] **1.2 — EKS Cluster**
  - Cluster IAM role (`telp-k8s-cluster-role`) — trusts eks.amazonaws.com
  - EKS cluster (`telp-k8s`) — v1.30, public endpoint locked to my IP, private endpoint for nodes
  - Node IAM role (`telp-k8s-node-role`) — WorkerNode, CNI, ECR, SSM, ELB policies
  - Bootstrap node group — 2x t3a.medium ON_DEMAND, AL2023 AMI
  - OIDC provider — enables IRSA (pod-level AWS permissions)

- [x] **1.3 — Karpenter IRSA**
  - Controller IRSA role (`telp-k8s-karpenter-controller`) — EC2, PassRole, Pricing, SQS
  - SQS queue (`telp-k8s-karpenter-interruption`) — spot interruption handling
  - EventBridge rules — spot interruption, rebalance, state-change → SQS

### Stack 2: cluster-addons (tooling installed via Helm)

- [x] **1.3b — Karpenter Helm + NodePool**
  - Helm release: Karpenter controller (v1.1.1) in kube-system
  - EC2NodeClass CRD: AL2023 AMI, karpenter.sh/discovery subnet/SG selection
  - NodePool CRD: amd64, spot+on-demand, t3a.medium/large + m5/m5a.large, 20 CPU limit

- [x] **1.4 — AWS Load Balancer Controller**
  - Helm release in kube-system
  - Region passed explicitly (AL2023 blocks IMDS from pods)
  - Uses node role permissions (ELB full access attached to node role)
  - Lesson learned: controller needs explicit --aws-region, can't auto-detect on AL2023

- [x] **1.5 — ArgoCD**
  - Helm release in argocd namespace
  - Service type: ClusterIP (access via port-forward, not LoadBalancer)
  - Dex (SSO) disabled, notifications disabled — lean for POC
  - timeout = 600s (ArgoCD is a large chart, needs time to start)
  - Lesson learned: LoadBalancer type hangs if ALB Controller can't provision; use ClusterIP

- [ ] **1.6 — ECR Repository**
  - Where your WordPress container image lives
  - Terraform creates it, pipeline pushes to it

- [ ] **1.7 — Security Groups / Networking**
  - Pod → RDS (port 3306)
  - Pod → Redis (port 6379)
  - ALB → Pod (port 80)

- [ ] **1.8 — IRSA role for S3 media**
  - Mirror of the EC2 role `todoelpaso-web-role` (created 2026-08-19), but with an
    OIDC trust policy for the WordPress service account instead of ec2.amazonaws.com
  - Least-privilege policy already proven on live:
    - `s3:ListBucket` on `arn:aws:s3:::todoelpaso-media`
    - `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject` on
      `arn:aws:s3:::todoelpaso-media/wp-content/uploads/*`
  - Note: bucket is in **us-east-1** while the cluster is us-west-2. Works fine,
    but uploads pay cross-region transfer. See the S3 region decision note below.

---

## Phase 2: Container Image (Docker)

This is the artifact that runs inside each pod. Built once,
runs identically everywhere.

- [ ] **2.1 — Dockerfile**
  - Base: official `wordpress:php8.2-fpm` (PHP-FPM, no Apache)
  - Install all 37 plugins at pinned versions
  - Install WP themes
  - Copy custom Nginx config
  - Set `DISALLOW_FILE_MODS = true` for production
  - Place health check endpoint

- [ ] **2.1b — S3 media mu-plugin (must be baked in)**
  - Copy `todoelpaso_live/s3-media-offload/s3-media-offload.php` → `wp-content/mu-plugins/`
  - AWS SDK **must** be present at `wp-content/mu-plugins/aws-sdk/aws-autoloader.php`.
    Either `composer require aws/aws-sdk-php` (preferred for the image) or copy the
    vendored 8 MB S3-only build already on the live box at that same path.
    Without it the plugin logs "AWS SDK not found" and silently disables offload.
  - wp-config constants required:
    `S3_OFFLOAD_BUCKET=todoelpaso-media`, `S3_OFFLOAD_REGION=us-east-1`,
    `S3_OFFLOAD_BASE_URL=https://todoelpaso-media.s3.amazonaws.com`,
    `S3_OFFLOAD_REMOVE_LOCAL=false`
  - **No credentials in the image.** Plugin uses the AWS default credential chain.
    On EC2 that resolves to the instance role; in EKS it resolves to IRSA
    (`AWS_ROLE_ARN` + `AWS_WEB_IDENTITY_TOKEN_FILE` injected by the webhook).
    No plugin code change needed to switch — this is why the chain is left alone.
  - Public image reads come from the **bucket policy** on
    `arn:aws:s3:::todoelpaso-media/wp-content/uploads/*`, not per-object ACLs.
    Never add an `ACL` param to putObject — it hard-fails under BucketOwnerEnforced.
  - `S3_OFFLOAD_REMOVE_LOCAL` must stay `false` unless/until every legacy object is
    confirmed on S3, because pods have no shared filesystem to fall back to.

- [ ] **2.2 — Nginx config**
  - `fastcgi_pass` to `127.0.0.1:9000` (PHP-FPM sidecar)
  - Serve static files (CSS/JS) directly
  - Health check location (`/healthz`)

- [ ] **2.3 — Build and push to ECR**
  - `docker build -t <ecr-repo>:v1.0.0 .`
  - `docker push <ecr-repo>:v1.0.0`

---

## Phase 3: Helm Chart (Kubernetes manifests, templated)

- [ ] **3.1 — Chart structure** (helm-charts/wordpress/)
- [ ] **3.2 — Deployment manifest** (nginx + php-fpm sidecar, shared volume)
- [ ] **3.3 — Service manifest** (ClusterIP, port 80)
- [ ] **3.4 — Ingress manifest** (ALB via annotations, host: k8s.todoelpaso.com)
- [ ] **3.5 — ConfigMap** (nginx.conf, wp-config values)
- [ ] **3.6 — Secrets** (DB password, Redis — from SSM or k8s Secret)

---

## Phase 4: ArgoCD Application (GitOps)

- [ ] **4.1 — Application manifest** (points at helm-charts/wordpress/)
- [ ] **4.2 — Demo: Git-driven deploy** (change image tag → push → auto-deploy)
- [ ] **4.3 — Demo: Self-heal** (kubectl delete pod → ArgoCD recreates)

---

## Phase 5: DNS + Cloudflare

- [ ] **5.1 — Subdomain** (k8s.todoelpaso.com CNAME → ALB DNS)

---

## Phase 6: Pipeline (CI/CD)

- [ ] **6.1 — GitHub Actions workflow** (build → push ECR → update values → commit)
- [ ] **6.2 — Staging workflow** (admin pod for plugin updates → rebuild image)

---

## Phase 7: Destroy (clean teardown)

- [ ] **7.1 — Destroy order**
  - `cd cluster-addons && terraform destroy` (removes Helm releases)
  - `cd eks-deploy && terraform destroy` (removes cluster + IAM + tags)
  - Verify: no orphaned ENIs, SGs, or EIPs left behind

---

---

## Deferred decision: move the media bucket to us-west-2

Measured 2026-08-19. Not urgent — recorded so the analysis isn't redone.

- Bucket `todoelpaso-media` is in **us-east-1**; everything else is us-west-2
- 22.2 GB, 161,933 objects, versioning disabled
- Total S3 spend is ~$2.50–4.00/month; egress is $0–2.88 of that
  (May 52.8 GB/$1.78 → Jun 68.6/$2.03 → Jul 88.9/$2.88 → Aug 56.5/$0.00)
- Images are served **direct from S3, not through Cloudflare**. Cloudflare can only
  proxy hostnames in the zone, and `*.s3.amazonaws.com` is not one. Verified:
  image responses return `Server: AmazonS3` with no CF headers.

Region alone buys almost nothing. The real win is putting the images on a hostname
Cloudflare *can* proxy, which gets edge caching and free bandwidth.

Catch: a plain CNAME `cdn.todoelpaso.com` → `todoelpaso-media.s3.amazonaws.com`
fails, because Cloudflare forwards `Host: cdn.todoelpaso.com` and S3 resolves the
bucket from the Host header (NoSuchBucket). Fix is either a Cloudflare Origin Rule
rewriting the Host, or naming the bucket after the hostname.

**Recommended plan when the time comes:** create `cdn.todoelpaso.com` as the bucket
name in us-west-2, sync, point `S3_OFFLOAD_BASE_URL` at it. One migration gets the
CDN, free egress, and the region change together.

Migration cost is small because the DB is clean: only ~9 rows hardcode the S3
hostname (3 `post_content`, 2 `wp_options`, 2 Elementor cache, 1 termmeta,
1 enclosure). The 24,219 `amazonS3_cache` postmeta rows are WP Offload's dead cache
and are never read. Sync itself is ~$1–2 and 30–90 min of server-side CopyObject.

**Trigger to act:** monthly egress consistently over ~100 GB (July was 88.9 GB),
at which point the free-tier stops absorbing it.

---

## Lessons Learned (add as we go)

- EKS 1.30 requires AL2023 AMI (`ami_type = "AL2023_x86_64_STANDARD"`) — AL2 not supported
- EKS doesn't allow version downgrades — destroy and recreate if you need a lower version
- After destroy/rebuild: must run `aws eks update-kubeconfig` (local kubeconfig is stale)
- ALB Controller on AL2023: IMDS blocked from pods, must pass `--aws-region` explicitly via Helm values
- ArgoCD with `type: LoadBalancer`: hangs if ALB can't provision external IP. Use ClusterIP + port-forward.
- ArgoCD timeout: default 5min too short. Set `timeout = 600` in Helm release.
- Separate Terraform stacks: Stack 1 (infra) runs first, Stack 2 (addons) reads Stack 1 outputs from tfvars
- Module variables: no defaults in modules. All values flow from root variables.tf → tfvars.
- Security groups from k8s (k8s-elb-*) are orphaned on destroy — cleanup script needed in deploy process
- WP Offload Pro ships a **namespace-prefixed** AWS SDK at `vendor/Aws3/` under
  `DeliciousBrains\WP_Offload_Media\Aws3\Aws\S3\S3Client` — checking for the standard
  `Aws\S3\S3Client` silently fails. Cost hours of "AWS SDK not found."
- EC2 IMDS with `HttpPutResponseHopLimit = 1` gives credentials to CLI but **not** to
  PHP-FPM. Symptom: works via wp-cli, fails via web. Needs hop limit 2.
  Does not apply in EKS — IRSA uses a projected token file, not IMDS.
- S3 objects with no ACL and no bucket policy return **403, not 404**. A blank image
  with a byte-correct object on S3 is a permissions problem, not a missing file.
- Prefer a bucket policy over per-object ACLs. An ACL is one API call that can fail
  per object; a policy is a property of the bucket that cannot be missed.
- Never write a "this is on S3" flag before confirming the upload succeeded, or a
  transient S3 failure permanently points the URL at something that isn't there.

---

## Access Commands (quick reference)

```bash
# Connect kubectl to cluster
aws eks update-kubeconfig --name telp-k8s --region us-west-2

# ArgoCD UI
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d
kubectl port-forward svc/argocd-server -n argocd 8080:80
# Browser: http://localhost:8080 (admin / <password from above>)

# Check cluster health
kubectl get nodes
kubectl get pods -A | grep -v Running
helm list -A
```
