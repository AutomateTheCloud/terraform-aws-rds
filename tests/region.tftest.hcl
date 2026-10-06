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

run "provider_region_by_default" {
  command = plan
  assert {
    condition     = output.metadata.aws.region.name == "us-east-1"
    error_message = "Expected the provider's Region."
  }
}

run "region_reaches_every_resource" {
  command = apply
  variables {
    region                 = "us-west-2"
    monitoring_interval    = 60
    read_replicas          = { count = 1 }
    cloudwatch_logs        = { exports = ["postgresql"] }
    security_group_ingress = { vpc = { cidr_ipv4 = "10.0.0.0/16" } }
  }
  assert {
    condition = alltrue([
      data.aws_region.this.region == "us-west-2",
      data.aws_service_principal.monitoring[0].region == "us-west-2",
      aws_db_instance.this.region == "us-west-2",
      aws_db_instance.replica[0].region == "us-west-2",
      aws_security_group.this.region == "us-west-2",
      aws_vpc_security_group_ingress_rule.this["vpc"].region == "us-west-2",
      aws_cloudwatch_log_group.this["app/postgresql"].region == "us-west-2",
      aws_cloudwatch_log_group.this["app-replica-1/postgresql"].region == "us-west-2",
    ])
    error_message = "region was not passed through to every resource."
  }
}
