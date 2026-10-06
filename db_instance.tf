# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_db_instance" "this" {
  region              = var.region
  identifier          = var.identifier
  engine              = var.engine
  engine_version      = var.engine_version
  instance_class      = var.instance_class
  license_model       = var.license_model
  snapshot_identifier = var.snapshot_identifier

  engine_lifecycle_support = var.engine_lifecycle_support
  db_name                  = var.db_name
  nchar_character_set_name = var.nchar_character_set_name
  parameter_group_name     = var.parameter_group_name
  option_group_name        = var.option_group_name

  # RDS creates the master password and keeps it in Secrets Manager, so it is never in
  # the Terraform state, except with read replicas (see secretsmanager_secret.tf). The
  # provider refuses false beside a password, so the unused argument is null.
  username                            = var.master_user.username
  manage_master_user_password         = local.manage_master_user_password ? true : null
  master_user_secret_kms_key_id       = local.manage_master_user_password ? var.master_user.secret_kms_key_id : null
  password                            = local.manage_master_user_password ? null : random_password.master[0].result
  iam_database_authentication_enabled = local.iam_database_authentication_enabled

  storage_type          = var.storage.type
  allocated_storage     = local.allocated_storage
  max_allocated_storage = var.storage.max_allocated
  iops                  = var.storage.iops
  storage_throughput    = var.storage.throughput
  storage_encrypted     = true
  kms_key_id            = var.kms_key_id

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = concat([aws_security_group.this.id], var.additional_security_group_ids)
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az
  port                   = local.port
  ca_cert_identifier     = var.ca_cert_identifier

  backup_retention_period   = var.backup.retention_period
  backup_window             = var.backup.window
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion.protection
  skip_final_snapshot       = var.deletion.skip_final_snapshot
  final_snapshot_identifier = "${var.identifier}-final-${random_id.final_snapshot.hex}"
  delete_automated_backups  = var.deletion.delete_automated_backups

  maintenance_window          = var.maintenance.window
  auto_minor_version_upgrade  = var.maintenance.auto_minor_version_upgrade
  allow_major_version_upgrade = var.maintenance.allow_major_version_upgrade
  apply_immediately           = var.maintenance.apply_immediately

  performance_insights_enabled          = var.performance_insights.enabled
  performance_insights_retention_period = var.performance_insights.enabled ? var.performance_insights.retention_period : null
  performance_insights_kms_key_id       = var.performance_insights.enabled ? var.kms_key_id : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.monitoring[0].arn : null

  enabled_cloudwatch_logs_exports = var.cloudwatch_logs.exports

  tags = local.tags

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  # AWS can change the master user name, and the snapshot a database came from, only by
  # replacing the database. A restored database also reports the snapshot's user name.
  lifecycle {
    ignore_changes = [username, snapshot_identifier]
  }

  # Log groups and ingress rules first, and, when they are replaced, the old ones are
  # deleted only after the instance has moved to the new ones.
  depends_on = [aws_cloudwatch_log_group.this, aws_vpc_security_group_ingress_rule.this, aws_iam_role_policy_attachment.monitoring]
}

resource "aws_db_instance" "replica" {
  count = var.read_replicas.count

  region              = var.region
  identifier          = local.replica_identifiers[count.index]
  replicate_source_db = aws_db_instance.this.identifier
  instance_class      = coalesce(var.read_replicas.instance_class, var.instance_class)
  multi_az            = var.read_replicas.multi_az

  # The engine, version, encryption, master user and subnet group come from the primary.
  parameter_group_name                = var.parameter_group_name
  option_group_name                   = var.option_group_name
  iam_database_authentication_enabled = local.iam_database_authentication_enabled

  # A replica is encrypted with the primary's key. AWS reports it as encrypted, and the
  # provider replaces a replica whose storage_encrypted is left unset (seen in AWS).
  storage_encrypted     = true
  storage_type          = var.storage.type
  max_allocated_storage = var.storage.max_allocated
  iops                  = var.storage.iops
  storage_throughput    = var.storage.throughput

  vpc_security_group_ids = concat([aws_security_group.this.id], var.additional_security_group_ids)
  publicly_accessible    = var.publicly_accessible
  port                   = local.port
  ca_cert_identifier     = var.ca_cert_identifier

  copy_tags_to_snapshot    = true
  deletion_protection      = var.deletion.protection
  skip_final_snapshot      = true
  delete_automated_backups = var.deletion.delete_automated_backups

  maintenance_window         = var.maintenance.window
  auto_minor_version_upgrade = var.maintenance.auto_minor_version_upgrade
  apply_immediately          = var.maintenance.apply_immediately

  performance_insights_enabled          = var.performance_insights.enabled
  performance_insights_retention_period = var.performance_insights.enabled ? var.performance_insights.retention_period : null
  performance_insights_kms_key_id       = var.performance_insights.enabled ? var.kms_key_id : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.monitoring[0].arn : null

  enabled_cloudwatch_logs_exports = var.cloudwatch_logs.exports

  tags = local.tags

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  # Renaming the primary renames it in AWS, and the replica follows. The provider reads
  # a changed replicate_source_db as a request to move the replica to another source,
  # which it refuses (seen in AWS), so the source is set only at create.
  lifecycle {
    ignore_changes = [replicate_source_db]
  }

  # Log groups and ingress rules first, and, when they are replaced, the old ones are
  # deleted only after the instance has moved to the new ones.
  depends_on = [aws_cloudwatch_log_group.this, aws_vpc_security_group_ingress_rule.this, aws_iam_role_policy_attachment.monitoring]
}
