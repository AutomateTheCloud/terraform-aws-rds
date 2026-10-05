# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "ap-southeast-7", description = "Asia Pacific (Thailand)" }
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

# Any Region plans, including ones added after this module was written.
run "region_not_in_old_tables" {
  command = plan
  variables { region = "ap-southeast-7" }
  assert {
    condition     = output.metadata.aws.region.abbr == "apse7" && aws_security_group.this.description == "Test - App Data [test] (ap-southeast-7): RDS app"
    error_message = "Unexpected abbreviation."
  }
}
