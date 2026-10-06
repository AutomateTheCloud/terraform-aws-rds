# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A configuration that creates the network, the key and the client security group in
# the same run as the database, so that their IDs are unknown when the module plans.
# Used only by tests/same_run.tftest.hcl, against a mocked provider.
terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "this" {
  for_each = { a = "10.0.1.0/24", b = "10.0.2.0/24" }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = "us-east-1${each.key}"
}

resource "aws_db_subnet_group" "this" {
  name       = "same-run"
  subnet_ids = [for s in aws_subnet.this : s.id]
}

resource "aws_kms_key" "this" {
  description         = "Same-run test key"
  enable_key_rotation = true
}

resource "aws_security_group" "app" {
  name   = "app"
  vpc_id = aws_vpc.this.id
}

module "rds" {
  source = "../../.."

  details              = { scope = "Test", purpose = "Same Run", environment = "test" }
  identifier           = "same-run"
  engine               = "postgres"
  instance_class       = "db.t4g.micro"
  vpc_id               = aws_vpc.this.id
  db_subnet_group_name = aws_db_subnet_group.this.name
  kms_key_id           = aws_kms_key.this.arn
  master_user          = { username = "dbadmin", secret_kms_key_id = aws_kms_key.this.arn }
  monitoring_interval  = 60
  read_replicas        = { count = 1 }
  cloudwatch_logs      = { exports = ["postgresql"], kms_key_id = aws_kms_key.this.arn }

  security_group_ingress = {
    app = { security_group_id = aws_security_group.app.id }
    vpc = { cidr_ipv4 = aws_vpc.this.cidr_block }
  }
}

output "metadata" {
  value = module.rds.metadata
}
