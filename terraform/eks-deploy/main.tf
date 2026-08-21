###############################################################################
# Step 1.1 — Subnet tagging for EKS discovery
#
# EKS and the AWS Load Balancer Controller discover subnets by tag.
# We add tags to the EXISTING subnets using aws_ec2_tag (additive only).
#
# aws_ec2_tag adds ONE tag to an existing resource. It does NOT manage
# the resource itself. On `terraform destroy`, only the tag is removed —
# the subnet stays exactly as it was.
###############################################################################

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# --- Private subnet tags ---
# These tell EKS "put internal load balancers here" and Karpenter "launch nodes here"
resource "aws_ec2_tag" "private_subnet_elb" {
  for_each    = toset(var.private_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_subnet_cluster" {
  for_each    = toset(var.private_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "private_subnet_karpenter" {
  for_each    = toset(var.private_subnet_ids)
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

# --- Public subnet tags ---
# These tell the AWS Load Balancer Controller "put internet-facing ALBs here"
resource "aws_ec2_tag" "public_subnet_elb" {
  for_each    = toset(var.public_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_subnet_cluster" {
  for_each    = toset(var.public_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}
