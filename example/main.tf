terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "example"
  region = "us-east-1"
}

##-----------------------------------------------------------------------------
# Module: RDS
module "rds" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope       = "Demo"
    purpose     = "RDS"
    environment = "dev"
    additional_tags = {
      "Project"   = "Project Name"
      "ProjectID" = "123456789"
      "Contact"   = "David Singer - david.singer@example.com"
    }
  }

  identifier     = "test-rds-database"
  multi_az       = true
  engine         = "postgres"
  engine_version = "14.2"
  db_name = "demo"
  # port    = 5555
  monitoring_interval = 15
  # encryption = {
    # enabled = true
    # kms_key_id = "alias/data-ee"
  # }
  instance = {
    class  = "db.t3.medium"
    public = false
    storage = {
      type          = "gp2"
      allocated     = 10
      max_allocated = 20
    }
  }
  credentials = {
    iam_authentication_enabled = true
    master = {
      username = "test"
      # password = "test1234"
    }
  }
  security_group_rules = [
    # {
      # source      = "sg-00000000000000001"
      # description = "Security Group Test"
    # },
    {
      source      = "10.0.0.0/8"
      description = "CIDR Test"
    }
  ]
  cloudwatch = {
    retention = 7
    exports   = ["postgresql"]
  }
  performance_insights = {
    enabled          = true
    retention_period = 7
  }
  backup = {
    retention_period = 2
    window           = "04:00-05:30"
  }
  maintenance = {
    window                     = "tue:06:00-tue:08:00"
    auto_minor_version_upgrade = true
    skip_final_snapshot        = true
    deletion_protection        = false
    apply_immediately          = true
  }
  db_subnet_group_name = "vpc-db-restricted-use1"
  ca_cert_identifier   = "rds-ca-2019"
  vpc_id               = "vpc-00000000000000001"
  replica = {
    count = 0
  }
  timeouts = {
    create = "180m"
    delete = "120m"
    update = "120m"
  }
}

##-----------------------------------------------------------------------------
# Outputs
output "metadata" {
  description = "Metadata"
  value       = module.rds.metadata
}
