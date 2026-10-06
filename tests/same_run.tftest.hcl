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
  mock_resource "aws_vpc" {
    defaults = { id = "vpc-0123456789abcdef0" }
  }
  mock_resource "aws_kms_key" {
    defaults = { arn = "arn:aws:kms:us-east-1:111111111111:key/1111" }
  }
  mock_resource "aws_security_group" {
    defaults = { id = "sg-0000000000000000d" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111111111111:role/rds-monitoring-0001" }
  }
}

mock_provider "random" {}

# The VPC, subnet group, key and client security group are created in the same run,
# so their IDs are unknown when the module plans. The rules, log groups and replica
# are decided from the inputs alone, so the plan succeeds.
run "same_run_plan" {
  command = plan
  module {
    source = "./tests/fixtures/same_run"
  }
  assert {
    condition     = toset(keys(module.rds.metadata.vpc_security_group_ingress_rule)) == toset(["app", "vpc"])
    error_message = "Both rules must be planned."
  }
}

run "same_run_apply" {
  command = apply
  module {
    source = "./tests/fixtures/same_run"
  }
  assert {
    condition     = output.metadata.vpc_security_group_ingress_rule["app"].referenced_security_group_id == aws_security_group.app.id && output.metadata.db_instance.kms_key_id == aws_kms_key.this.arn
    error_message = "The same-run security group and key must reach the module."
  }
}
