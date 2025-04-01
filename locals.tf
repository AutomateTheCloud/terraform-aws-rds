locals {
  database_master_password = try(var.credentials.master.password, null) != null ? var.credentials.master.password : random_password.master_password.result

  kms_key_id = try(var.encryption.enabled, true) ? try(var.encryption.kms_key_id, "alias/aws/rds") : null
  port       = try(var.port, null) != null ? var.port : local.port_default_lookup["${var.engine}"]

  port_default_lookup = {
    mariadb        = "3306"
    mysql          = "3306"
    oracle-ee      = "1521"
    oracle-ee-cdb  = "1521"
    oracle-se2     = "1521"
    oracle-se2-cdb = "1521"
    postgres       = "5432"
    sqlserver-ee   = "1433"
    sqlserver-se   = "1433"
    sqlserver-ex   = "1433"
    sqlserver-web  = "1433"
  }

  replica_cloudwatch_groups = flatten([
    for j in range(1, try(var.replica.count, 0) + 1) : [
      for i in try(var.cloudwatch.exports, []) : {
        identifier       = "${var.identifier}-replica-${j}",
        cloudwatch_group = i
      }
    ]
  ])
}
