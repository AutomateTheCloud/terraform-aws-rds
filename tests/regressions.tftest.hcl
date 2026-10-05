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

# The old module sent an IPv6 range as a source security group ID.
run "ipv6_source_is_a_range" {
  command = plan
  variables {
    security_group_ingress = { v6 = { cidr_ipv6 = "2600:1f18:1234:5600::/56" } }
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["v6"].cidr_ipv6 == "2600:1f18:1234:5600::/56" && aws_vpc_security_group_ingress_rule.this["v6"].referenced_security_group_id == null
    error_message = "An IPv6 range must be sent as cidr_ipv6."
  }
}

# The old module looked the port up in a table of eleven engines, and failed for any
# other, such as Db2 or the SQL Server Developer editions. Every engine the module
# accepts now has a port, known at plan time.
run "every_engine_has_a_port" {
  command = plan
  variables {
    engine                 = "db2-se"
    security_group_ingress = { vpc = { cidr_ipv4 = "10.0.0.0/16" } }
  }
  assert {
    condition     = aws_db_instance.this.port == 50000 && aws_vpc_security_group_ingress_rule.this["vpc"].from_port == 50000
    error_message = "Db2 must use port 50000."
  }
}

run "sql_server_developer_port" {
  command = plan
  variables {
    engine                 = "sqlserver-dev-ee"
    security_group_ingress = { vpc = { cidr_ipv4 = "10.0.0.0/16" } }
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["vpc"].from_port == 1433
    error_message = "SQL Server must use port 1433."
  }
}

# The old role name, rds_em-<identifier>, was over IAM's 64 characters for long
# identifiers, and collided between Regions.
run "monitoring_role_long_identifier" {
  command = plan
  variables {
    identifier          = "a23456789012345678901234567890123456789012345678901234567890123"
    monitoring_interval = 60
  }
  assert {
    condition     = aws_iam_role.monitoring[0].name_prefix == "rds-monitoring-"
    error_message = "The role name must not depend on the identifier."
  }
}

# The old module ignored changes to engine_version and identifier.
run "create" {
  command = apply
  variables {
    engine_version = "16"
  }
}

run "version_upgrade_and_rename_are_planned" {
  command = plan
  variables {
    engine_version = "17"
    identifier     = "app-renamed"
    maintenance    = { allow_major_version_upgrade = true }
  }
  assert {
    condition     = aws_db_instance.this.engine_version == "17" && aws_db_instance.this.identifier == "app-renamed"
    error_message = "A new engine version or identifier must be planned."
  }
}

# The old log groups were positional: adding a log type moved every replica's groups.
run "adding_a_log_type_keeps_the_others" {
  command = plan
  variables {
    engine_version  = "16"
    read_replicas   = { count = 1 }
    cloudwatch_logs = { exports = ["upgrade", "postgresql"] }
  }
  assert {
    condition     = toset(keys(aws_cloudwatch_log_group.this)) == toset(["app/postgresql", "app/upgrade", "app-replica-1/postgresql", "app-replica-1/upgrade"])
    error_message = "Log groups must be keyed by instance and log type."
  }
}
