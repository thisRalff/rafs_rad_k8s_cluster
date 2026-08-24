###############################################################################
# Data Sources: read-only references to existing VPC Infrastructure
###############################################################################

# The existing production VPC and all VPC resources attached to the ID
data "aws_vpc" "existing" {
  id = var.vpc_id
}

# Current AWS account (for scoping SSM/KMS ARNs)
data "aws_caller_identity" "current" {}
