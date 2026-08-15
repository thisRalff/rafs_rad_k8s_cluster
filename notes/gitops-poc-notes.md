# GitOps POC - Study Notes

Running notes for interview prep. Covers concepts discussed while building the
Terraform/EKS/Karpenter/ArgoCD proof of concept.

---

## Kubernetes / Helm / ArgoCD - how they stack

- **Kubernetes (EKS)**: the orchestration layer. Schedules containers onto
  nodes, handles service discovery, scaling, self-healing, manages desired
  state via objects (Deployments, Services, ConfigMaps, etc.).
- **Helm**: a package manager for Kubernetes. Templates raw YAML into
  versioned "charts" with variables (`values.yaml`), so an app can be
  installed/upgraded/rolled back as one unit instead of hand-managing dozens
  of manifest files.
- **ArgoCD**: a GitOps continuous delivery tool. Watches a git repo (holding
  Helm charts or raw manifests) and continuously reconciles the live cluster
  state to match what's declared in git. Detects drift and can auto-heal it.

**Typical flow:**
1. Helm chart lives in a git repo (often separate from app source code -
   "config repo" vs "app repo")
2. ArgoCD points at that repo/path, continuously syncs it into the cluster
3. CI builds the app image, updates the image tag in Helm values, commits -
   ArgoCD picks up the change and deploys

**Why GitOps (ArgoCD) beats push-based CD (Jenkins running `kubectl apply`):**
- Git becomes the single source of truth
- Automatic drift detection / self-healing if someone manually changes
  something in-cluster (ArgoCD reverts it back to match git)
- Easier audit trail (every change is a git commit) and easier rollback
  (`git revert`)

---

## EKS subnet requirements

- EKS control plane requires subnets in **at least 2 AZs** (AWS recommends 3
  for real workloads, 2 is the hard minimum).
- Need a **public/private split**:
  - Public subnets: host NAT Gateway(s) and any internet-facing load balancer
  - Private subnets: where worker nodes/pods actually live (no public IPs;
    reach the internet via NAT for image pulls etc.) - standard security
    posture
- **Subnet tags EKS tooling looks for (auto-discovery):**
  - Public: `kubernetes.io/role/elb = 1`
  - Private: `kubernetes.io/role/internal-elb = 1`
  - Both: `kubernetes.io/cluster/<cluster-name> = shared` (or `owned`)
  - Private (for Karpenter specifically): `karpenter.sh/discovery = <cluster-name>`
- **NAT Gateway cost tradeoff**: one NAT per AZ = full HA, costs more
  (~$64/mo vs ~$32/mo for a single shared NAT). Single NAT is a fine POC
  tradeoff to call out explicitly as a cost-vs-HA decision if asked.

---

## OIDC, IRSA, and STS - how pods get AWS permissions without static keys

This is the concept most likely to get probed in an interview, so the precise
version:

**The problem being solved:** pods (Karpenter, ArgoCD, the AWS Load Balancer
Controller, etc.) sometimes need to call AWS APIs. The old bad options were:
static AWS access keys baked into a Secret/ConfigMap (leak risk, no rotation),
or a broad IAM role attached to the whole EC2 node (every pod on that node
inherits the same permissions - large blast radius).

**STS (Security Token Service)** is the AWS service that has *always* issued
short-lived, temporary credentials when something assumes an IAM role
(`sts:AssumeRole`). This predates Kubernetes entirely - it's the same
mechanism used for cross-account access, federated login, etc.

**OIDC (OpenID Connect) provider** is a *trust registration*, not a
credential mechanism itself. EKS clusters can issue signed OIDC tokens to
Kubernetes service accounts. Registering an OIDC provider in AWS IAM tells
IAM: "tokens signed by this specific cluster's issuer are legitimate, and can
be used to request credentials via STS."

**Correction/clarity point:** OIDC is not "STS but more efficient" - they are
two different pieces of the same mechanism, not alternatives. OIDC provides a
new *trust source* that STS can accept, via the `AssumeRoleWithWebIdentity`
API call specifically. STS still does the actual work of issuing the
temporary credentials, same as it always has - OIDC just adds Kubernetes
service account identities as something STS can trust.

**IRSA (IAM Roles for Service Accounts)** = OIDC provider + IAM role trust
policy + STS's `AssumeRoleWithWebIdentity`, put together. This is the actual
"replaces hardcoded keys" mechanism.

**Full flow, concretely:**
1. EKS cluster acts as an OIDC identity provider, issuing signed tokens to
   service accounts
2. AWS IAM registers that issuer as a trusted OIDC provider
   (`aws_iam_openid_connect_provider` - this is the whole job of the `oidc`
   Terraform module)
3. A separate IAM role is created with a trust policy scoped to: "trust
   tokens from this OIDC provider, specifically for service account X in
   namespace Y" (this is the next module to build - not done yet)
4. The Kubernetes service account gets annotated with that role's ARN
5. When the pod starts, it gets a short-lived OIDC token, calls STS
   `AssumeRoleWithWebIdentity` to exchange it for temporary AWS credentials
   scoped to exactly what that role allows - nothing more, and the
   credentials auto-rotate

**Why not just give the node role broad EC2 permissions instead?**
Blast radius. A node-wide role means every pod scheduled on that node
inherits those permissions, even pods that have nothing to do with AWS. IRSA
scopes access to exactly the service account that needs it.

**History - has EKS always worked this way?**
No. Two things to separate:
- **OIDC as a protocol** predates EKS by years (OIDC dates to ~2014, built on
  OAuth 2.0).
- **IRSA specifically** (EKS's native use of OIDC for pod-level IAM) launched
  **September 3, 2019**, requiring EKS 1.13+ (clusters updated on/after that
  date) or 1.14+ for new clusters
  ([AWS announcement](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/)).

**Before IRSA existed (pre-Sept 2019), how did pods get AWS credentials?**
- **Node-wide IAM instance profile** (the default/only native option): one
  broad IAM role attached to the EC2 instance profile for worker nodes.
  Every pod on that node inherited the same permissions - the exact blast
  radius problem IRSA was built to fix.
- **kube2iam / kiam**: popular third-party open-source projects (not built by
  AWS) that intercepted pod calls to the EC2 instance metadata service and
  returned different, per-pod-scoped credentials based on pod annotations -
  the community's workaround for the same problem, before AWS shipped a
  native solution.
- Static access keys in Secrets also happened in practice in some shops, even
  though it was already recognized as bad practice - there just wasn't a
  good native alternative yet.

So there wasn't a single "key stashed somewhere previously" as the sanctioned
mechanism - it was either the coarse node-wide role, or third-party tooling
(kube2iam/kiam) filling the gap, until AWS shipped native OIDC-based IRSA.

**Do you need to own a domain for the OIDC issuer URL? No.**
The OIDC issuer URL is required (OIDC always needs an issuer URL to work),
but EKS auto-generates and hosts it for you the moment the cluster exists -
you don't provision, buy, or manage DNS/certs for it. It comes back in the
form:

```
https://oidc.eks.<region>.amazonaws.com/id/<cluster-id>
```

That's an AWS-owned endpoint. In the Terraform, this is
`aws_eks_cluster.this.identity[0].oidc[0].issuer` - it's an *output* of the
cluster resource, not something we supply as input. The `oidc` module just
takes that AWS-generated URL and registers it with IAM
(`aws_iam_openid_connect_provider`); the `tls_certificate` data source fetches
the TLS cert from that same AWS URL to compute the thumbprint IAM uses for
validation. Nothing custom to own or manage.

**Granularity: per-pod or per-ServiceAccount?**
Per-ServiceAccount, not literally per-pod. One Kubernetes ServiceAccount (in a
specific namespace) maps to one IAM role. Any pod configured to run under
that ServiceAccount inherits that role's permissions. If 10 pods share one
ServiceAccount, they share one IAM role. True fine-grained scoping only
happens if you deliberately give each distinct workload its own dedicated
ServiceAccount -> its own IAM role. Nothing forces that discipline - you
could still be lazy and put everything under one ServiceAccount, which just
recreates the old blast-radius problem at a smaller scale. The *capability*
for fine-grained, per-workload scoping is what IRSA provides; actually
achieving it depends on how many ServiceAccounts you bother to create.

**How many ServiceAccounts can a cluster have?**
No AWS-documented hard limit specific to ServiceAccounts (unlike e.g.
Services, which are capped at 5,000/namespace and 10,000/cluster). They're
just another Kubernetes API object stored in etcd, same as Pods/Deployments/
Secrets. In practice you'd never hit a ServiceAccount-specific ceiling first.
The limit that actually matters for IRSA specifically: your **AWS account's
IAM role quota** (default 1,000 roles/account, soft limit, raisable) - since
each ServiceAccount that needs distinct AWS permissions needs its own IAM
role. IAM role count bites before ServiceAccount count ever would.

**How the OIDC provider, IAM role, and ServiceAccount actually connect:**
The OIDC provider resource itself is "dumb" by design - it's only a trust
anchor ("I trust tokens signed by this cluster's issuer"). It does NOT know
about or store anything about individual service accounts. There's exactly
one OIDC provider per cluster, full stop, no matter how many workloads exist.
The actual per-service-account scoping happens in two other places:

1. **The IAM role's trust policy** - references a *specific* service account
   by namespace and name, via a condition on the OIDC token's `sub` claim:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Principal": {
         "Federated": "arn:aws:iam::<account-id>:oidc-provider/oidc.eks.<region>.amazonaws.com/id/<cluster-id>"
       },
       "Action": "sts:AssumeRoleWithWebIdentity",
       "Condition": {
         "StringEquals": {
           "oidc.eks.<region>.amazonaws.com/id/<cluster-id>:sub": "system:serviceaccount:karpenter:karpenter",
           "oidc.eks.<region>.amazonaws.com/id/<cluster-id>:aud": "sts.amazonaws.com"
         }
       }
     }]
   }
   ```

   The `:sub` condition is the actual scoping mechanism: "only trust tokens
   where the subject claim equals `system:serviceaccount:<namespace>:<name>`."
   Each workload needing its own permissions gets its own IAM role with its
   own trust policy, pointing at the *same* OIDC provider but a different
   `:sub` value.

2. **The Kubernetes ServiceAccount object**, annotated with the role ARN it's
   allowed to use:

   ```yaml
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: karpenter
     namespace: karpenter
     annotations:
       eks.amazonaws.com/role-arn: arn:aws:iam::<account-id>:role/karpenter-controller-role
   ```

   When a pod runs under that ServiceAccount, EKS's pod identity webhook
   injects a projected token plus `AWS_ROLE_ARN`/`AWS_WEB_IDENTITY_TOKEN_FILE`
   env vars automatically. The AWS SDK inside the pod picks those up and calls
   STS on its own - no app code changes needed.

**Direct answer: do we configure different service accounts inside the OIDC
provider config?** No. The OIDC provider resource never changes, regardless
of how many service accounts/workloads get added later. Every new workload
needing AWS access just means: one more IAM role (trust policy scoped via
`:sub` to that specific service account) + one more annotated ServiceAccount
in Kubernetes. The OIDC provider is shared infrastructure underneath all of
them - built once per cluster.

**Who actually owns creating the ServiceAccount object - Terraform or
something else?**
The IAM side (role + trust policy + permission policy) is real Terraform
work, built and owned by Terraform end to end - this is exactly what the
Karpenter IRSA module will do. The Kubernetes ServiceAccount object itself is
a nuance: it *can* be created via Terraform's `kubernetes` provider
(`kubernetes_service_account` resource), but in real-world practice it's very
often NOT created that way. More common pattern: **Helm charts create it for
you.** Karpenter's own Helm chart has a values.yaml setting like
`serviceAccount.annotations` where you just pass in the role ARN, and the
chart creates the ServiceAccount object with that annotation baked in as part
of `helm install`. That's the plan for this project: Terraform builds the IAM
role and outputs its ARN, that ARN gets fed into the Karpenter Helm release
as a value, and the Helm chart creates the annotated ServiceAccount.

Mental model: Terraform owns the IAM half end to end. The Kubernetes
ServiceAccount half is often owned by whatever's deploying the workload (a
Helm chart, in this project's case) rather than raw Terraform - Terraform
just hands that tool the role ARN as an input.

**Does Helm "dole out" permissions to service accounts? No - correcting a
tempting but wrong mental model.**
Helm has zero involvement in permissions. It only templates: it takes a role
ARN passed in as a Helm value and stamps it onto the ServiceAccount object's
metadata as an annotation string. Helm has no concept of IAM, no awareness of
what that ARN can or can't do, and makes no authorization decisions - it's
pure "take this string, put it in this YAML field."

The permission decision was already made earlier, in Terraform, before Helm
ever runs: Role_1 already exists with its trust policy scoped to SA-1's name
and already has permission_policy_x attached; Role_2 already exists scoped to
SA-2 with permission_policy_y. Helm's only job is: "here's Role_1's ARN,
stamp it onto SA-1's annotation," and same for SA-2/Role_2.

The actual *enforcement* of "SA-1 can do X, SA-2 can do Y" happens at AWS STS,
at the moment a pod tries to use its credentials - STS checks the trust
policy on whichever role the ServiceAccount's annotation points to, allows or
denies the `AssumeRoleWithWebIdentity` call based on the pre-existing `:sub`
condition, then scopes the resulting temp credentials to whatever the
permission policy on that role allows.

**Chain of custody, precisely:**
Terraform decides the permissions (creates roles + policies, each trust
policy pre-authorizing a specific service-account *name string* - Terraform
never touches or creates the actual k8s ServiceAccount object, it only
pre-authorizes a name pattern) -> Helm wires the ServiceAccount to the
correct pre-built role ARN (pure templating/data plumbing, no logic, no
permissions logic of any kind) -> AWS STS enforces it at runtime, issuing one
set of short-lived, auto-rotating temporary credentials per pod startup via
`AssumeRoleWithWebIdentity`, scoped to whatever that one role allows.

**General principle worth stating in an interview (not IRSA-specific):** no
IAM permission set - role, user, or group policy, doesn't matter - has any
awareness of what it's attached to or who's using it. It's just a static
document of allowed/denied actions. This is true across all of AWS IAM, not
a quirk of Terraform or Kubernetes. IRSA doesn't change this - it just adds a
new *trust source* (OIDC federated identity) that's allowed to request
`AssumeRoleWithWebIdentity` against a role whose permission document was
already sitting there, unaware, the whole time.

**Compressed, interview-ready version of the OIDC/STS distinction (the kind
of nuance that gets probed):**
- OIDC does not issue credentials. It doesn't "make keys." It provides
  *trust* - it's what lets a Kubernetes service account's token be recognized
  as a legitimate identity that's allowed to ask for access to a permission
  set.
- STS is what actually grants the temporary credentials, once that trust
  check passes - one `AssumeRoleWithWebIdentity` exchange per pod
  startup, scoped to exactly the one role's permission set that pod's
  ServiceAccount is trusted for.
- A senior interviewer asking "walk me through what OIDC does here" is often
  listening for exactly this distinction - "OIDC gives you credentials" is
  the wrong/sloppy answer; "OIDC establishes trust so STS will grant
  credentials" is the correct one.

**One-sentence version to have ready:** Terraform pre-authorizes IAM roles,
each trusting a specific service-account name via OIDC; Helm's values just
tell each ServiceAccount which pre-built role ARN to reference; and at
runtime, STS is what actually exchanges each pod's OIDC token for temporary,
auto-rotating credentials scoped to that role. OIDC itself never issues
credentials - it's the trust plumbing that makes AWS IAM willing to let STS
honor tokens from this specific cluster in the first place.

**Scope of what OIDC/IRSA covers (and what it doesn't):**
- Covers: pod-to-AWS-API calls (Karpenter launching EC2 instances, ArgoCD
  reading AWS Secrets Manager, etc.)
- Does NOT cover: the EKS control plane's own permissions (that's the
  separate `aws_iam_role.cluster` with `AmazonEKSClusterPolicy` - lets the
  EKS *service* manage resources on your behalf)
- Does NOT cover: ArgoCD's connection to your git repo (that's a separate git
  token/SSH key, unrelated to AWS IAM entirely)

---

## Cost notes (POC-scale)

- Helm, ArgoCD, Karpenter: all free, open source (CNCF projects). No
  licensing cost.
- What actually costs money is the underlying AWS infra:
  - EKS control plane: ~$0.10/hr (~$73/mo if left running continuously)
  - EC2 nodes (or Fargate): small POC nodes = a few dollars for a couple
    weeks of intermittent use
  - Karpenter-provisioned nodes: cost while they exist under load, should
    scale back down after
  - NAT Gateway + EIP, EBS volumes, load balancers if exposed: minor but
    non-zero
- Practical lever: `terraform destroy` between work sessions instead of
  leaving the cluster running - the control plane bills whether it's being
  used or not.

---

## Job description gap analysis (for interview prep)

Original gap found comparing resume to job spec (Terraform/Helm/ArgoCD/EKS/
Karpenter GitOps role):

- **Missing entirely**: Kubernetes/EKS, Helm, ArgoCD, Karpenter, GitHub
  Actions/ARC, Octopus Deploy, Aqua Security
- **Adjacent but not equivalent**: ECS/Fargate container experience (not
  same as k8s), AWS Inspector (not same product category as Aqua), GitLab CI
  depth (transferable but not GitHub Actions specifically)
- **Strong / no gap**: Terraform module authoring, Ansible, Python/Bash/
  PowerShell, SonarQube, Jenkins exposure, CI/CD architecture instincts
  (plan-as-source-of-truth, drift detection, reusable module libraries)

**Interview question mapping:**
1. Largest CI/CD transformation led -> Ochsner Epic pipeline (strong answer)
2. Challenged a design, proposed alternative -> MIDAS NLB/EBS Multi-Attach vs
   FSx decision (strong answer)
3. Reusable frameworks, how many teams consumed them -> need an actual number
   ready (currently a quantification gap, not a skills gap)
4. Beyond EKS, what AWS services architected at scale -> strong breadth
   (VPC/TGW, RDS, Lambda, DynamoDB, SQS, API Gateway, GovCloud, IAM/STS, EC2
   Image Builder) but the question's framing assumes EKS as a baseline, which
   isn't there yet - this POC is meant to close exactly that gap

**Approach decided on:** don't claim production Helm/ArgoCD experience that
isn't real - a technical screener finds the seams fast. Instead: build a real
small POC (this project) to genuinely close the gap, and be upfront in the
interview about ramping fast on k8s-specific tooling while leaning on real
Terraform/CI-CD architecture depth as the differentiator.

---

## Demo ideas for the POC (ranked by impact/effort)

1. **Self-heal demo**: deploy via ArgoCD, manually break it
   (`kubectl delete`/`edit` live), watch ArgoCD auto-revert to git state.
   Highest visual impact for lowest effort.
2. **Git-driven deploy**: commit an image tag bump, watch ArgoCD auto-sync on
   screen. Directly demonstrates the job spec's core ask.
3. **Progressive delivery / canary** (Argo Rollouts): senior-level touch,
   separates from "did a tutorial" candidates.
4. **Karpenter scaling under load**: load test, watch nodes provision then
   scale back down. Demonstrates cost-aware autoscaling awareness.
5. **Multi-environment promotion** (app-of-apps pattern): less flashy live,
   but directly answers the "reusable framework, multiple teams" interview
   question.

**Best combo for effort spent**: #1 + #2 together tell one complete story -
git is the source of truth, and the cluster enforces it both directions.
Layer in Karpenter (#4) if time allows since it's explicitly in the job spec.
