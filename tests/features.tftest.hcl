# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_service_principal" {
    defaults = { name = "monitoring.rds.amazonaws.com" }
  }
  mock_resource "aws_db_instance" {
    defaults = {
      arn                = "arn:aws:rds:us-east-1:111111111111:db:app"
      address            = "app.abcdefghijkl.us-east-1.rds.amazonaws.com"
      port               = 5432
      master_user_secret = [{ secret_arn = "arn:aws:secretsmanager:us-east-1:111111111111:secret:rds!db-0000-abcdef", kms_key_id = "arn:aws:kms:us-east-1:111111111111:key/0000", secret_status = "active" }]
    }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111111111111:role/rds-monitoring-0001" }
  }
  mock_resource "aws_security_group" {
    defaults = { id = "sg-0000000000000000d" }
  }
}

mock_provider "random" {}

variables {
  details              = { scope = "Test", purpose = "App Data", environment = "test" }
  identifier           = "app"
  engine               = "postgres"
  instance_class       = "db.t4g.micro"
  vpc_id               = "vpc-0123456789abcdef0"
  db_subnet_group_name = "private"
  master_user          = { username = "dbadmin" }
}

# Plan runs come first: the runs in a file share one state, and these must plan a
# fresh instance.
run "performance_insights_off" {
  command = plan
  variables {
    kms_key_id           = "arn:aws:kms:us-east-1:111111111111:key/1111"
    performance_insights = { enabled = false }
  }
  assert {
    condition     = aws_db_instance.this.performance_insights_enabled == false
    error_message = "Performance Insights must be off."
  }
}

run "restore_from_snapshot" {
  command = plan
  variables {
    master_user         = {}
    snapshot_identifier = "app-before-upgrade"
  }
  assert {
    condition     = aws_db_instance.this.snapshot_identifier == "app-before-upgrade" && aws_db_instance.this.manage_master_user_password == true
    error_message = "A restore must plan without a master user name or size, and keep the password in Secrets Manager."
  }
}

run "iam_authentication_by_engine" {
  command = plan
  variables {
    engine = "oracle-se2"
  }
  assert {
    condition     = aws_db_instance.this.iam_database_authentication_enabled == false
    error_message = "IAM authentication must be off for engines without it."
  }
}

run "iam_authentication_off" {
  command = plan
  variables {
    engine                              = "mysql"
    iam_database_authentication_enabled = false
  }
  assert {
    condition     = aws_db_instance.this.iam_database_authentication_enabled == false
    error_message = "IAM authentication must follow the input."
  }
}

# SQL Server and Db2 allow replicas of a database whose password RDS manages.
run "replicas_keep_managed_password_on_sql_server" {
  command = plan
  variables {
    engine        = "sqlserver-ee"
    license_model = "license-included"
    read_replicas = { count = 1 }
  }
  assert {
    condition     = aws_db_instance.this.manage_master_user_password == true && length(aws_secretsmanager_secret.master) == 0 && length(random_password.master) == 0
    error_message = "SQL Server replicas must keep the RDS-managed password."
  }
}

run "most_options" {
  command = apply
  variables {
    engine_version                = "17"
    engine_lifecycle_support      = "open-source-rds-extended-support-disabled"
    kms_key_id                    = "arn:aws:kms:us-east-1:111111111111:key/1111"
    master_user                   = { username = "dbadmin", secret_kms_key_id = "alias/secrets" }
    additional_security_group_ids = ["sg-0aaaaaaaaaaaaaaaa"]
    multi_az                      = true
    port                          = 5433
    ca_cert_identifier            = "rds-ca-ecc384-g1"
    db_name                       = "app"
    parameter_group_name          = "app-postgres17"
    monitoring_interval           = 30
    storage                       = { type = "gp3", allocated = 400, max_allocated = 1000, iops = 12000, throughput = 500 }
    backup                        = { retention_period = 14, window = "03:00-04:00" }
    maintenance                   = { window = "sun:05:00-sun:06:00", apply_immediately = true, allow_major_version_upgrade = true }
    deletion                      = { protection = false, skip_final_snapshot = true, delete_automated_backups = false }
    performance_insights          = { enabled = true, retention_period = 31 }
    cloudwatch_logs               = { exports = ["postgresql", "upgrade"], retention_in_days = 30, kms_key_id = "arn:aws:kms:us-east-1:111111111111:key/2222" }
    read_replicas                 = { count = 2, instance_class = "db.t4g.small", multi_az = true }
    security_group_ingress = {
      app      = { security_group_id = "sg-0bbbbbbbbbbbbbbbb", description = "Application servers" }
      office   = { cidr_ipv4 = "10.20.0.0/16" }
      ipv6     = { cidr_ipv6 = "2600:1f18:1234:5600::/56" }
      partners = { prefix_list_id = "pl-0123456789abcdef0" }
    }
  }

  assert {
    condition     = aws_db_instance.this.kms_key_id == "arn:aws:kms:us-east-1:111111111111:key/1111" && aws_db_instance.this.performance_insights_kms_key_id == "arn:aws:kms:us-east-1:111111111111:key/1111" && aws_db_instance.this.performance_insights_retention_period == 31
    error_message = "kms_key_id must encrypt storage and Performance Insights."
  }
  assert {
    condition     = aws_db_instance.this.manage_master_user_password == null && aws_db_instance.this.password == random_password.master[0].result && aws_db_instance.this.username == "dbadmin"
    error_message = "With PostgreSQL replicas, the module must set the master password itself."
  }
  assert {
    condition     = aws_secretsmanager_secret.master[0].kms_key_id == "alias/secrets" && startswith(aws_secretsmanager_secret.master[0].name_prefix, "rds-app-master-") && aws_secretsmanager_secret_version.master[0].secret_id == aws_secretsmanager_secret.master[0].id
    error_message = "The module's secret must use master_user.secret_kms_key_id."
  }
  assert {
    condition     = jsondecode(aws_secretsmanager_secret_version.master[0].secret_string) == { username = "dbadmin", password = random_password.master[0].result }
    error_message = "The secret must hold the user name and password, like an RDS-managed secret."
  }
  assert {
    condition     = random_password.master[0].length == 30 && !strcontains(random_password.master[0].override_special, "/") && !strcontains(random_password.master[0].override_special, "@") && !strcontains(random_password.master[0].override_special, "\"")
    error_message = "The password must fit every engine and avoid characters RDS refuses."
  }
  assert {
    condition     = output.metadata.secretsmanager_secret.arn == aws_secretsmanager_secret.master[0].arn
    error_message = "The module's secret must be in metadata."
  }
  assert {
    condition     = aws_db_instance.this.vpc_security_group_ids == toset(["sg-0000000000000000d", "sg-0aaaaaaaaaaaaaaaa"]) && alltrue([for r in aws_db_instance.replica : r.vpc_security_group_ids == toset(["sg-0000000000000000d", "sg-0aaaaaaaaaaaaaaaa"])])
    error_message = "Additional security groups must reach the primary and every replica."
  }
  assert {
    condition     = aws_db_instance.this.storage_type == "gp3" && aws_db_instance.this.allocated_storage == 400 && aws_db_instance.this.max_allocated_storage == 1000 && aws_db_instance.this.iops == 12000 && aws_db_instance.this.storage_throughput == 500
    error_message = "Unexpected storage."
  }
  assert {
    condition     = aws_db_instance.this.backup_retention_period == 14 && aws_db_instance.this.backup_window == "03:00-04:00" && aws_db_instance.this.maintenance_window == "sun:05:00-sun:06:00"
    error_message = "Unexpected backup or maintenance windows."
  }
  assert {
    condition     = aws_db_instance.this.deletion_protection == false && aws_db_instance.this.skip_final_snapshot == true && aws_db_instance.this.delete_automated_backups == false
    error_message = "Unexpected deletion settings."
  }
  assert {
    condition     = aws_db_instance.this.engine_lifecycle_support == "open-source-rds-extended-support-disabled" && aws_db_instance.this.ca_cert_identifier == "rds-ca-ecc384-g1" && aws_db_instance.this.port == 5433
    error_message = "Unexpected engine settings."
  }
  assert {
    condition     = [for r in aws_db_instance.replica : r.identifier] == ["app-replica-1", "app-replica-2"] && alltrue([for r in aws_db_instance.replica : r.replicate_source_db == "app" && r.instance_class == "db.t4g.small" && r.multi_az == true && r.skip_final_snapshot == true])
    error_message = "Unexpected replicas."
  }
  assert {
    condition     = alltrue([for r in aws_db_instance.replica : r.performance_insights_kms_key_id == "arn:aws:kms:us-east-1:111111111111:key/1111" && r.monitoring_interval == 30 && r.monitoring_role_arn == "arn:aws:iam::111111111111:role/rds-monitoring-0001" && r.enabled_cloudwatch_logs_exports == toset(["postgresql", "upgrade"]) && r.parameter_group_name == "app-postgres17"])
    error_message = "Replicas must share the primary's monitoring, logs and parameter group."
  }
  assert {
    condition     = aws_db_instance.this.monitoring_interval == 30 && aws_db_instance.this.monitoring_role_arn == "arn:aws:iam::111111111111:role/rds-monitoring-0001"
    error_message = "Enhanced Monitoring must use the module's role."
  }
  assert {
    condition     = aws_iam_role.monitoring[0].name_prefix == "rds-monitoring-" && aws_iam_role_policy_attachment.monitoring[0].policy_arn == "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
    error_message = "Unexpected monitoring role."
  }
  assert {
    condition     = jsondecode(aws_iam_role.monitoring[0].assume_role_policy).Statement[0] == { Effect = "Allow", Principal = { Service = "monitoring.rds.amazonaws.com" }, Action = "sts:AssumeRole", Condition = { StringEquals = { "aws:SourceAccount" = "111111111111" } } }
    error_message = "The monitoring role must trust only RDS acting for this account."
  }
  assert {
    condition = toset(keys(aws_cloudwatch_log_group.this)) == toset([
      "app/postgresql", "app/upgrade", "app-replica-1/postgresql", "app-replica-1/upgrade", "app-replica-2/postgresql", "app-replica-2/upgrade",
    ]) && aws_cloudwatch_log_group.this["app-replica-2/upgrade"].name == "/aws/rds/instance/app-replica-2/upgrade"
    error_message = "One log group per instance and log type expected."
  }
  assert {
    condition     = alltrue([for g in aws_cloudwatch_log_group.this : g.retention_in_days == 30 && g.kms_key_id == "arn:aws:kms:us-east-1:111111111111:key/2222"])
    error_message = "Unexpected log group settings."
  }
  assert {
    condition = alltrue([
      aws_vpc_security_group_ingress_rule.this["app"].referenced_security_group_id == "sg-0bbbbbbbbbbbbbbbb",
      aws_vpc_security_group_ingress_rule.this["app"].description == "Application servers",
      aws_vpc_security_group_ingress_rule.this["office"].cidr_ipv4 == "10.20.0.0/16",
      aws_vpc_security_group_ingress_rule.this["office"].description == "office",
      aws_vpc_security_group_ingress_rule.this["ipv6"].cidr_ipv6 == "2600:1f18:1234:5600::/56",
      aws_vpc_security_group_ingress_rule.this["partners"].prefix_list_id == "pl-0123456789abcdef0",
    ])
    error_message = "Unexpected ingress rule sources."
  }
  assert {
    condition     = alltrue([for r in aws_vpc_security_group_ingress_rule.this : r.ip_protocol == "tcp" && r.from_port == 5433 && r.to_port == 5433 && r.security_group_id == "sg-0000000000000000d"])
    error_message = "Each rule must allow the port the instance listens on, TCP only."
  }
  assert {
    condition = alltrue([
      length(output.metadata.db_instance_replica) == 2,
      output.metadata.db_instance_replica[1].identifier == "app-replica-2",
      output.metadata.iam_role.arn == "arn:aws:iam::111111111111:role/rds-monitoring-0001",
      output.metadata.cloudwatch_log_group["app/postgresql"].retention_in_days == 30,
      output.metadata.vpc_security_group_ingress_rule["office"].cidr_ipv4 == "10.20.0.0/16",
    ])
    error_message = "Unexpected metadata output."
  }
}
