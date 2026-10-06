# Copyright 2026 Automate the Cloud Inc.
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

run "additional_security_group_ids_not_ids" {
  command = plan
  variables {
    additional_security_group_ids = ["app"]
  }
  expect_failures = [var.additional_security_group_ids]
}

run "backup_retention_too_long" {
  command = plan
  variables {
    backup = { retention_period = 36 }
  }
  expect_failures = [var.backup]
}

run "backup_retention_fraction" {
  command = plan
  variables {
    backup = { retention_period = 1.5 }
  }
  expect_failures = [var.backup]
}


run "backup_window_format" {
  command = plan
  variables {
    backup = { window = "3:00-4:00" }
  }
  expect_failures = [var.backup]
}

run "logs_wrong_engine" {
  command = plan
  variables {
    cloudwatch_logs = { exports = ["slowquery"] }
  }
  expect_failures = [var.cloudwatch_logs]
}

run "logs_twice" {
  command = plan
  variables {
    cloudwatch_logs = { exports = ["postgresql", "postgresql"] }
  }
  expect_failures = [var.cloudwatch_logs]
}

run "logs_retention" {
  command = plan
  variables {
    cloudwatch_logs = { exports = ["postgresql"], retention_in_days = 10 }
  }
  expect_failures = [var.cloudwatch_logs]
}

run "logs_kms_not_arn" {
  command = plan
  variables {
    cloudwatch_logs = { kms_key_id = "alias/logs" }
  }
  expect_failures = [var.cloudwatch_logs]
}

run "db_name_format" {
  command = plan
  variables {
    db_name = "1app"
  }
  expect_failures = [var.db_name]
}

run "db_name_sqlserver" {
  command = plan
  variables {
    engine  = "sqlserver-ex"
    db_name = "app"
  }
  expect_failures = [var.db_name]
}

run "db_subnet_group_empty" {
  command = plan
  variables {
    db_subnet_group_name = " "
  }
  expect_failures = [var.db_subnet_group_name]
}

run "engine_aurora" {
  command = plan
  variables {
    engine = "aurora-postgresql"
  }
  expect_failures = [var.engine]
}

run "engine_lifecycle_value" {
  command = plan
  variables {
    engine_lifecycle_support = "disabled"
  }
  expect_failures = [var.engine_lifecycle_support]
}

run "engine_lifecycle_engine" {
  command = plan
  variables {
    engine                   = "mariadb"
    engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  }
  expect_failures = [var.engine_lifecycle_support]
}

run "iam_auth_oracle" {
  command = plan
  variables {
    engine                              = "oracle-se2"
    iam_database_authentication_enabled = true
  }
  expect_failures = [var.iam_database_authentication_enabled]
}

run "identifier_uppercase" {
  command = plan
  variables {
    identifier = "App"
  }
  expect_failures = [var.identifier]
}

run "identifier_double_hyphen" {
  command = plan
  variables {
    identifier = "app--db"
  }
  expect_failures = [var.identifier]
}

run "identifier_trailing_hyphen" {
  command = plan
  variables {
    identifier = "app-"
  }
  expect_failures = [var.identifier]
}

run "identifier_leading_digit" {
  command = plan
  variables {
    identifier = "1app"
  }
  expect_failures = [var.identifier]
}

run "identifier_too_long" {
  command = plan
  variables {
    identifier = "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  }
  expect_failures = [var.identifier]
}

run "identifier_too_long_for_replicas" {
  command = plan
  variables {
    identifier    = "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    read_replicas = { count = 1 }
  }
  expect_failures = [var.identifier]
}

run "identifier_52_with_replicas" {
  command = plan
  variables {
    identifier    = "abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    read_replicas = { count = 1 }
  }
}

run "instance_class_format" {
  command = plan
  variables {
    instance_class = "t4g.micro"
  }
  expect_failures = [var.instance_class]
}

run "kms_key_not_arn" {
  command = plan
  variables {
    kms_key_id = "alias/rds"
  }
  expect_failures = [var.kms_key_id]
}

run "license_model_value" {
  command = plan
  variables {
    license_model = "byol"
  }
  expect_failures = [var.license_model]
}

run "maintenance_window_format" {
  command = plan
  variables {
    maintenance = { window = "Sun:05:00-Sun:06:00" }
  }
  expect_failures = [var.maintenance]
}

run "username_required" {
  command = plan
  variables {
    master_user = {}
  }
  expect_failures = [var.master_user]
}

run "username_not_needed_for_snapshot" {
  command = plan
  variables {
    master_user         = {}
    snapshot_identifier = "app-before-upgrade"
  }
}

run "username_format" {
  command = plan
  variables {
    master_user = { username = "db-admin" }
  }
  expect_failures = [var.master_user]
}

run "monitoring_interval_value" {
  command = plan
  variables {
    monitoring_interval = 20
  }
  expect_failures = [var.monitoring_interval]
}

run "nchar_not_oracle" {
  command = plan
  variables {
    nchar_character_set_name = "UTF8"
  }
  expect_failures = [var.nchar_character_set_name]
}

run "performance_insights_retention" {
  command = plan
  variables {
    performance_insights = { retention_period = 30 }
  }
  expect_failures = [var.performance_insights]
}

run "performance_insights_retention_62" {
  command = plan
  variables {
    performance_insights = { retention_period = 62 }
  }
}

run "port_too_low" {
  command = plan
  variables {
    port = 80
  }
  expect_failures = [var.port]
}

run "replicas_too_many" {
  command = plan
  variables {
    read_replicas = { count = 16 }
  }
  expect_failures = [var.read_replicas]
}

run "replicas_class" {
  command = plan
  variables {
    read_replicas = { count = 1, instance_class = "t4g.micro" }
  }
  expect_failures = [var.read_replicas]
}

run "replicas_need_backups" {
  command = plan
  variables {
    read_replicas = { count = 1 }
    backup        = { retention_period = 0 }
  }
  expect_failures = [var.read_replicas]
}

run "ingress_two_sources" {
  command = plan
  variables {
    security_group_ingress = { app = { cidr_ipv4 = "10.0.0.0/16", security_group_id = "sg-0123456789abcdef0" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "ingress_no_source" {
  command = plan
  variables {
    security_group_ingress = { app = { description = "nothing" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "ingress_ipv6_in_ipv4" {
  command = plan
  variables {
    security_group_ingress = { app = { cidr_ipv4 = "2600:1f18::/56" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "ingress_ipv4_in_ipv6" {
  command = plan
  variables {
    security_group_ingress = { app = { cidr_ipv6 = "10.0.0.0/16" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "storage_type_value" {
  command = plan
  variables {
    storage = { type = "gp4" }
  }
  expect_failures = [var.storage]
}

run "storage_allocated_fraction" {
  command = plan
  variables {
    storage = { allocated = 20.5 }
  }
  expect_failures = [var.storage]
}

run "storage_max_not_more" {
  command = plan
  variables {
    storage = { allocated = 100, max_allocated = 100 }
  }
  expect_failures = [var.storage]
}

run "storage_iops_gp2" {
  command = plan
  variables {
    storage = { type = "gp2", iops = 3000 }
  }
  expect_failures = [var.storage]
}

run "storage_iops_required" {
  command = plan
  variables {
    storage = { type = "io2", allocated = 100 }
  }
  expect_failures = [var.storage]
}

run "storage_throughput_io1" {
  command = plan
  variables {
    storage = { type = "io1", allocated = 100, iops = 1000, throughput = 500 }
  }
  expect_failures = [var.storage]
}

run "vpc_id_format" {
  command = plan
  variables {
    vpc_id = "0123456789abcdef0"
  }
  expect_failures = [var.vpc_id]
}
