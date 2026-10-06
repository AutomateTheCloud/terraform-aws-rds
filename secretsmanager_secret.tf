# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# AWS does not create read replicas of a database whose master password RDS manages in
# Secrets Manager, except for SQL Server and Db2. With replicas on any other engine, the
# module creates the password, sets it on the database, and keeps it in a secret of its
# own. The password is then also in the Terraform state.
resource "random_password" "master" {
  count = local.manage_master_user_password ? 0 : 1

  # 30 characters fits every engine's limit (Oracle allows 30). RDS refuses /, ", @
  # and spaces in master passwords.
  length           = 30
  special          = true
  override_special = "!#$%^&*()-_=+[]{}:?"
}

resource "aws_secretsmanager_secret" "master" {
  count = local.manage_master_user_password ? 0 : 1

  region                  = var.region
  name_prefix             = "rds-${var.identifier}-master-"
  description             = "Master user of the RDS database ${var.identifier}, created by Terraform"
  kms_key_id              = var.master_user.secret_kms_key_id
  recovery_window_in_days = 7

  tags = local.tags

  # Renaming the database keeps the secret, and its ARN, as RDS does with its own.
  lifecycle {
    ignore_changes = [name_prefix]
  }
}

# The same keys as the secrets RDS manages, so applications read either the same way.
resource "aws_secretsmanager_secret_version" "master" {
  count = local.manage_master_user_password ? 0 : 1

  region    = var.region
  secret_id = aws_secretsmanager_secret.master[0].id
  secret_string = jsonencode({
    username = aws_db_instance.this.username
    password = random_password.master[0].result
  })
}
