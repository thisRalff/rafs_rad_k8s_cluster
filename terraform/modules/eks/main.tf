###############################################################################
# EKS Module — Cluster + Bootstrap Node Group
###############################################################################

# EKS Cluster (control plane)
resource "aws_eks_cluster" "eks_telp_web" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = concat(var.private_subnet_ids, var.public_subnet_ids)

    # Public: your kubectl from home (locked to your IP)
    endpoint_public_access = true
    public_access_cidrs    = var.public_access_cidrs

    # Private: nodes/pods reach API internally
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]

  tags = merge(var.tags, { Name = var.cluster_name })
}

# Bootstrap Node Group
resource "aws_eks_node_group" "bootstrap" {
  cluster_name    = aws_eks_cluster.eks_telp_web.name
  node_group_name = "${var.cluster_name}-bootstrap"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.node_instance_types
  capacity_type  = "ON_DEMAND"
  ami_type       = var.node_ami_type

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
    aws_iam_role_policy_attachment.node_ssm,
  ]

  tags = merge(var.tags, { Name = "${var.cluster_name}-bootstrap" })
}
