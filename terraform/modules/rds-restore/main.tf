###############################################################################
# rds-restore module
#
# Restores a manual snapshot of the production WordPress DB into a SEPARATE,
# isolated RDS instance for the cluster. The production database is never
# touched — this instance is an independent copy.
#
# Access: a dedicated security group allows MySQL/MariaDB (3306) ONLY from the
# EKS cluster security group (which every node/pod carries), using an
# SG-to-SG reference rather than a CIDR range.
###############################################################################

resource "aws_security_group" "db" {
  name        = "${var.identifier}-db"
  description = "Restored WordPress DB - allow 3306 from EKS cluster SG only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.identifier}-db" })
}

# Inbound: only the EKS cluster/node SG may reach the DB port.
resource "aws_security_group_rule" "db_ingress_from_cluster" {
  type                     = "ingress"
  description              = "MySQL/MariaDB from EKS cluster nodes/pods"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = var.allowed_source_security_group_id
}

resource "aws_security_group_rule" "db_egress_all" {
  type              = "egress"
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db.id
}

# Restored instance from the production snapshot. Credentials, engine, and
# storage come from the snapshot, so we do not set username/password here.
resource "aws_db_instance" "restore" {
  identifier              = var.identifier
  snapshot_identifier     = var.snapshot_identifier
  instance_class          = var.instance_class
  db_subnet_group_name    = var.db_subnet_group_name
  vpc_security_group_ids  = [aws_security_group.db.id]
  publicly_accessible     = false
  multi_az                = false
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
  copy_tags_to_snapshot   = true
  backup_retention_period = 0

  # These are inherited from the source snapshot; declaring them so Terraform's
  # config matches the live resource and does NOT force a replacement.
  storage_encrypted = true
  storage_type      = "gp3"
  allocated_storage = 20

  tags = merge(var.tags, { Name = var.identifier })
}
