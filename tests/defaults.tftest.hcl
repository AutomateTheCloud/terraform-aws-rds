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

run "defaults_are_secure" {
  command = apply

  assert {
    condition     = aws_db_instance.this.storage_encrypted == true && aws_db_instance.this.kms_key_id != null
    error_message = "The database must be encrypted."
  }
  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "The database must not be public by default."
  }
  assert {
    condition     = aws_db_instance.this.manage_master_user_password == true && aws_db_instance.this.password == null && length(aws_secretsmanager_secret.master) == 0 && length(random_password.master) == 0
    error_message = "The master password must be managed by RDS in Secrets Manager, never set by the module."
  }
  assert {
    condition     = aws_db_instance.this.deletion_protection == true && aws_db_instance.this.skip_final_snapshot == false && startswith(aws_db_instance.this.final_snapshot_identifier, "app-final-")
    error_message = "Deletion protection and a final snapshot must be on by default."
  }
  assert {
    condition     = aws_db_instance.this.backup_retention_period == 7 && aws_db_instance.this.copy_tags_to_snapshot == true
    error_message = "Automated backups must be kept for 7 days by default."
  }
  assert {
    condition     = aws_db_instance.this.iam_database_authentication_enabled == true
    error_message = "IAM authentication must be on by default for PostgreSQL."
  }
  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 0
    error_message = "No network access may be allowed by default."
  }
  assert {
    condition     = aws_db_instance.this.vpc_security_group_ids == toset(["sg-0000000000000000d"])
    error_message = "Only the module's security group expected."
  }
  assert {
    condition     = aws_db_instance.this.storage_type == "gp3" && aws_db_instance.this.allocated_storage == 20 && aws_db_instance.this.max_allocated_storage == null
    error_message = "Unexpected storage defaults."
  }
  assert {
    condition     = aws_db_instance.this.multi_az == false && aws_db_instance.this.monitoring_interval == 0 && length(aws_iam_role.monitoring) == 0
    error_message = "Multi-AZ and Enhanced Monitoring must be off by default."
  }
  assert {
    condition     = aws_db_instance.this.performance_insights_enabled == false
    error_message = "Performance Insights must be off by default: small MySQL and MariaDB classes do not support it."
  }
  assert {
    condition     = aws_db_instance.this.ca_cert_identifier != "rds-ca-2019"
    error_message = "The expired rds-ca-2019 must not be the default."
  }
  assert {
    condition     = length(aws_cloudwatch_log_group.this) == 0 && length(aws_db_instance.this.enabled_cloudwatch_logs_exports) == 0
    error_message = "No logs are published by default."
  }
  assert {
    condition     = aws_db_instance.this.auto_minor_version_upgrade == true && aws_db_instance.this.allow_major_version_upgrade == false && aws_db_instance.this.apply_immediately == false
    error_message = "Unexpected maintenance defaults."
  }
  assert {
    condition     = aws_db_instance.this.tags == tomap({ Scope = "Test", Purpose = "App Data", Environment = "test" })
    error_message = "Unexpected tags."
  }
  assert {
    condition     = startswith(aws_security_group.this.name_prefix, "rds-app-") && aws_security_group.this.tags["Name"] == "rds-app" && aws_security_group.this.vpc_id == "vpc-0123456789abcdef0"
    error_message = "Unexpected security group."
  }
  assert {
    condition     = aws_security_group.this.description == "Test - App Data [test] (us-east-1): RDS app"
    error_message = "Unexpected security group description."
  }
  assert {
    condition = alltrue([
      output.metadata.db_instance.address == "app.abcdefghijkl.us-east-1.rds.amazonaws.com",
      output.metadata.db_instance.port == 5432,
      output.metadata.db_instance.master_user_secret[0].secret_arn == "arn:aws:secretsmanager:us-east-1:111111111111:secret:rds!db-0000-abcdef",
      output.metadata.db_instance_replica == null,
      output.metadata.secretsmanager_secret == null,
      output.metadata.vpc_security_group_ingress_rule == null,
      output.metadata.cloudwatch_log_group == null,
      output.metadata.iam_role == null,
      output.metadata.iam_role_policy_attachment == null,
      output.metadata.security_group.id == "sg-0000000000000000d",
      output.metadata.aws.region.abbr == "use1",
      output.metadata.aws.account.id == "111111111111",
    ])
    error_message = "Unexpected metadata output."
  }
}

run "abbreviation_override" {
  command = plan
  variables {
    details = { scope = "Test", purpose = "App Data", environment = "Production", environment_abbr = "prd", additional_tags = { CostCenter = "1234" } }
  }
  assert {
    condition     = output.metadata.details.environment.abbr == "prd" && output.metadata.details.purpose.machine == "appdata" && aws_db_instance.this.tags["CostCenter"] == "1234"
    error_message = "Unexpected details handling."
  }
}

# Characters AWS refuses in a security group description are dropped.
run "description_characters" {
  command = plan
  variables {
    details = { scope = "Café <Test>", purpose = "App Data", environment = "test" }
  }
  assert {
    condition     = aws_security_group.this.description == "Caf Test - App Data [test] (us-east-1): RDS app"
    error_message = "Unexpected description: ${aws_security_group.this.description}"
  }
}

run "details_scope_required" {
  command = plan
  variables {
    details = { scope = " ", purpose = "App Data", environment = "test" }
  }
  expect_failures = [var.details]
}

run "details_purpose_required" {
  command = plan
  variables {
    details = { scope = "Test", purpose = "", environment = "test" }
  }
  expect_failures = [var.details]
}

run "details_environment_required" {
  command = plan
  variables {
    details = { scope = "Test", purpose = "App Data", environment = "" }
  }
  expect_failures = [var.details]
}
