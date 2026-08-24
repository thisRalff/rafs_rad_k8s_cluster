###############################################################################
# Operator ALB security group — single network source of truth.
#
# This SG is attached to the shared `telp-operator` ALB (via the ingress
# annotation) and is the ONLY place the operator CIDR is enforced. The CIDR
# comes from ignored terraform.tfvars, so no IP is ever committed to Git.
###############################################################################

resource "aws_security_group" "operator_alb" {
  name        = "${var.cluster_name}-operator-alb"
  description = "Restrict shared operator ALB ingress to operator CIDRs"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from operator CIDRs only"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.operator_allowed_cidrs
  }

  egress {
    description = "Allow all outbound (ALB to targets)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-operator-alb"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
