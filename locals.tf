# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  # The Name tag of the security group, and the start of its name.
  name = "rds-${var.identifier}"

  # A group description may contain only these characters, so anything else in the
  # details names is dropped rather than failing the create.
  security_group_description = substr(replace(
    "${local.scope.name} - ${local.purpose.name} [${local.environment.name}] (${local.aws.region.name}): RDS ${var.identifier}",
    "/[^A-Za-z0-9 ._:/()#,@\\[\\]+=&;{}!$*-]/", ""
  ), 0, 255)

  # The port the instance listens on: var.port, or the engine's default. Known from the
  # inputs, so the ingress rules can be created with a new security group before the
  # instance moves to it. The engine is validated, so every family is in the map.
  port = coalesce(var.port, {
    postgres  = 5432
    mysql     = 3306
    mariadb   = 3306
    oracle    = 1521
    sqlserver = 1433
    db2       = 50000
  }[split("-", var.engine)[0]])

  # IAM authentication is on by default for the engines that support it.
  iam_database_authentication_enabled = coalesce(var.iam_database_authentication_enabled, contains(["postgres", "mysql", "mariadb"], var.engine))

  # RDS keeps the master password in Secrets Manager, unless there are read replicas on
  # an engine for which AWS refuses that (see secretsmanager_secret.tf).
  manage_master_user_password = var.read_replicas.count == 0 || startswith(var.engine, "sqlserver") || startswith(var.engine, "db2")

  # 20 GiB unless restoring, when the snapshot's size is kept.
  allocated_storage = var.storage.allocated != null ? var.storage.allocated : (var.snapshot_identifier == null ? 20 : null)

  replica_identifiers = [for n in range(1, var.read_replicas.count + 1) : "${var.identifier}-replica-${n}"]

  # One log group per instance and log type, keyed "<identifier>/<log type>". Built from
  # the inputs alone, so adding a log type or a replica never moves another group.
  cloudwatch_log_groups = merge([
    for id in concat([var.identifier], local.replica_identifiers) : {
      for log_type in var.cloudwatch_logs.exports : "${id}/${log_type}" => "/aws/rds/instance/${id}/${log_type}"
    }
  ]...)
}
