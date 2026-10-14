locals {
  identifier = "${var.name_prefix}-postgres"
}

resource "aws_db_subnet_group" "this" {
  name       = local.identifier
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "database" {
  name        = local.identifier
  description = "PostgreSQL database"
  vpc_id      = var.vpc_id

  tags = {
    Name = local.identifier
  }
}

resource "aws_vpc_security_group_ingress_rule" "database" {
  for_each = var.allowed_security_group_ids

  security_group_id            = aws_security_group.database.id
  description                  = "PostgreSQL from ${each.key}"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = each.value
}

resource "aws_db_instance" "this" {
  identifier     = local.identifier
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage_gb
  max_allocated_storage = var.max_allocated_storage_gb
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name                     = var.db_name
  username                    = var.master_username
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period    = var.backup_retention_days
  copy_tags_to_snapshot      = true
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.skip_final_snapshot ? null : "${local.identifier}-final"
  auto_minor_version_upgrade = true
  apply_immediately          = var.apply_immediately
}

resource "aws_secretsmanager_secret_rotation" "master_password" {
  count = var.master_password_rotation_days == null ? 0 : 1

  secret_id          = aws_db_instance.this.master_user_secret[0].secret_arn
  rotate_immediately = false

  rotation_rules {
    automatically_after_days = var.master_password_rotation_days
  }
}
