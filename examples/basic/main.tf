# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A private, encrypted PostgreSQL database in the subnets you give, reachable on its
# port from anywhere in the VPC. RDS keeps the master password in AWS Secrets Manager.

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

data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_db_subnet_group" "this" {
  name        = "example-basic"
  description = "Private subnets for the example-basic database"
  subnet_ids  = var.subnet_ids
}

module "rds" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "App Data"
    environment = "Development"
  }

  identifier           = "example-basic"
  engine               = "postgres"
  engine_version       = "17"
  instance_class       = "db.t3.micro"
  vpc_id               = var.vpc_id
  db_subnet_group_name = aws_db_subnet_group.this.name
  master_user          = { username = "dbadmin" }

  security_group_ingress = {
    vpc = { cidr_ipv4 = data.aws_vpc.this.cidr_block, description = "Anything in the VPC" }
  }
}

output "database" {
  description = "Where to connect, and the ARN of the Secrets Manager secret that holds the master password"
  value = {
    address    = module.rds.metadata.db_instance.address
    port       = module.rds.metadata.db_instance.port
    secret_arn = module.rds.metadata.db_instance.master_user_secret[0].secret_arn
  }
}
