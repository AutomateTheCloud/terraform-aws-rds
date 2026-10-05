# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A PostgreSQL database for production use: a customer managed KMS key, a standby in
# a second Availability Zone, one read replica, a parameter group, logs in CloudWatch,
# Enhanced Monitoring and Performance Insights, and access only from the application's
# security group.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC to create the database in"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of private subnets for the database, in at least two Availability Zones"
  type        = list(string)
}

locals {
  details = {
    scope       = "Example"
    purpose     = "App Data"
    environment = "Production"
  }
}

# The key that encrypts the database, its snapshots, its replica, Performance Insights
# and the master password's secret. With a read replica, the module creates that
# secret: AWS does not create replicas of a database whose password RDS manages. Its default key policy lets IAM principals in this
# account use it, which RDS and Secrets Manager need.
resource "aws_kms_key" "this" {
  description             = "example-complete database"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_db_subnet_group" "this" {
  name        = "example-complete"
  description = "Private subnets for the example-complete database"
  subnet_ids  = var.subnet_ids
}

# Engine settings. PostgreSQL 15 and later refuse unencrypted connections by default;
# this also logs slow statements.
resource "aws_db_parameter_group" "this" {
  name   = "example-complete-postgres17"
  family = "postgres17"

  # AWS applies this parameter at the next restart, and reports it that way; any other
  # apply_method shows as a change in every plan.
  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
}

# The application servers' group. Only its members may connect to the database.
resource "aws_security_group" "app" {
  name_prefix = "example-complete-app-"
  description = "Application servers for example-complete"
  vpc_id      = var.vpc_id
}

module "rds" {
  source = "../../"

  details = local.details

  identifier               = "example-complete"
  engine                   = "postgres"
  engine_version           = "17"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  instance_class           = "db.t4g.small"
  vpc_id                   = var.vpc_id
  db_subnet_group_name     = aws_db_subnet_group.this.name
  parameter_group_name     = aws_db_parameter_group.this.name
  db_name                  = "app"
  kms_key_id               = aws_kms_key.this.arn
  master_user              = { username = "dbadmin", secret_kms_key_id = aws_kms_key.this.arn }
  multi_az                 = true

  storage = {
    allocated     = 20
    max_allocated = 100
  }

  backup = {
    retention_period = 14
    window           = "03:00-04:00"
  }

  maintenance = {
    window = "sun:05:00-sun:06:00"
  }

  read_replicas = { count = 1 }

  monitoring_interval  = 60
  performance_insights = { enabled = true, retention_period = 7 }
  cloudwatch_logs = {
    exports           = ["postgresql", "upgrade"]
    retention_in_days = 30
  }

  security_group_ingress = {
    app = { security_group_id = aws_security_group.app.id, description = "Application servers" }
  }
}

output "database" {
  description = "Where to connect, the replica's address, and the ARN of the Secrets Manager secret that holds the master password"
  value = {
    address         = module.rds.metadata.db_instance.address
    port            = module.rds.metadata.db_instance.port
    replica_address = module.rds.metadata.db_instance_replica[0].address
    secret_arn      = module.rds.metadata.secretsmanager_secret.arn
  }
}

output "app_security_group_id" {
  description = "The security group to attach to the application servers"
  value       = aws_security_group.app.id
}
