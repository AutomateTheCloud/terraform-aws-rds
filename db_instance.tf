resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = var.engine
  engine_version = var.engine_version

  instance_class = try(var.instance.class, null)

  publicly_accessible = try(var.instance.public, false)

  storage_type          = try(var.instance.storage.type, null)
  storage_encrypted     = try(var.encryption.enabled, true)
  kms_key_id            = try(data.aws_kms_key.rds[0].arn, null)
  iops                  = try(var.instance.storage.iops, null)
  allocated_storage     = try(var.instance.storage.allocated, null)
  max_allocated_storage = try(var.instance.storage.max_allocated, null)

  license_model = var.license_model

  db_name                             = var.db_name
  iam_database_authentication_enabled = try(var.credentials.iam_authentication_enabled, null)
  username                            = try(var.credentials.master.username, null)
  password                            = local.database_master_password
  port                                = local.port

  multi_az               = var.multi_az
  vpc_security_group_ids = concat([aws_security_group.this.id], var.security_groups_additional)
  db_subnet_group_name   = var.db_subnet_group_name
  parameter_group_name   = var.parameter_group_name
  option_group_name      = var.option_group_name

  final_snapshot_identifier = "${var.identifier}-${random_id.snapshot_identifier.hex}-FINAL"
  skip_final_snapshot       = try(var.maintenance.skip_final_snapshot, null)

  deletion_protection      = try(var.maintenance.deletion_protection, false)
  delete_automated_backups = try(var.maintenance.delete_automated_backups, true)

  backup_retention_period = try(var.backup.retention_period, null)
  backup_window           = try(var.backup.window, null)
  copy_tags_to_snapshot   = true

  maintenance_window          = try(var.maintenance.window, null)
  auto_minor_version_upgrade  = try(var.maintenance.auto_minor_version_upgrade, null)
  allow_major_version_upgrade = try(var.maintenance.allow_major_version_upgrade, null)
  apply_immediately           = try(var.maintenance.apply_immediately, false)

  performance_insights_enabled          = try(var.performance_insights.enabled, true)
  performance_insights_retention_period = try(var.performance_insights.retention_period, null)
  performance_insights_kms_key_id       = try(var.performance_insights.enabled, true) ? try(data.aws_kms_key.rds[0].arn, null) : null

  enabled_cloudwatch_logs_exports = try(var.cloudwatch.exports, null)

  ca_cert_identifier       = var.ca_cert_identifier
  nchar_character_set_name = var.nchar_character_set_name

  monitoring_role_arn = (var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null)
  monitoring_interval = var.monitoring_interval

  snapshot_identifier = var.snapshot_identifier

  lifecycle {
    ignore_changes = [
      snapshot_identifier,
      identifier,
      engine_version,
      username,
      password
    ]
  }
  tags     = local.tags
  provider = aws.this

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }
}

resource "aws_db_instance" "replica" {
  count               = try(var.replica.count, 0)
  identifier          = "${var.identifier}-replica-${count.index + 1}"
  replicate_source_db = aws_db_instance.this.identifier

  instance_class = try(var.replica.class, var.instance.class, null)

  publicly_accessible = try(var.instance.public, false)

  storage_type          = try(var.replica.storage.type, var.instance.storage.type, null)
  kms_key_id            = try(data.aws_kms_key.rds[0].arn, null)
  iops                  = try(var.replica.storage.iops, var.instance.storage.iops, null)
  max_allocated_storage = try(var.instance.storage.max_allocated, null)

  license_model = var.license_model

  iam_database_authentication_enabled = try(var.credentials.iam_authentication_enabled, null)
  port                                = local.port

  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = var.parameter_group_name
  option_group_name      = var.option_group_name

  skip_final_snapshot = true

  deletion_protection = try(var.maintenance.deletion_protection, false)

  maintenance_window          = try(var.maintenance.window, null)
  auto_minor_version_upgrade  = try(var.maintenance.auto_minor_version_upgrade, null)
  allow_major_version_upgrade = try(var.maintenance.allow_major_version_upgrade, null)
  apply_immediately           = try(var.maintenance.apply_immediately, false)

  performance_insights_enabled          = try(var.performance_insights.enabled, true)
  performance_insights_retention_period = try(var.performance_insights.retention_period, null)
  performance_insights_kms_key_id       = try(var.performance_insights.enabled, true) ? try(data.aws_kms_key.rds[0].arn, null) : null

  enabled_cloudwatch_logs_exports = try(var.cloudwatch.exports, null)

  ca_cert_identifier       = var.ca_cert_identifier
  nchar_character_set_name = var.nchar_character_set_name

  monitoring_role_arn = (var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null)
  monitoring_interval = var.monitoring_interval

  lifecycle {
    ignore_changes = [
      storage_encrypted,
      identifier,
      engine_version,
      username,
      password
    ]
  }
  tags     = local.tags
  provider = aws.this

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }
}
