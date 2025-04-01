# AWS - RDS - Terraform Module
Terraform module for creating RDS Databases (AutomateTheCloud model)

***

## Usage
```hcl
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
  # enabled = false
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
    skip_final_snapshot        = false
    deletion_protection        = false
    apply_immediately          = true
  }
  db_subnet_group_name = "vpc-db-restricted-use1"
  ca_cert_identifier   = "rds-ca-2019"
  vpc_id               = "vpc-00000000000000001"

  replica = {
    count = 1
  }
  timeouts = {
    create = "180m"
    delete = "120m"
    update = "120m"
  }
}
```

***

## Inputs
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `autoscaling` | Autoscaling (TODO - Info) | `any` | |
| `backup` | Backup (TODO - Info) | `any` | |
| `ca_cert_identifier` | The identifier of the CA certificate for the DB instances | `string` | `rds-ca-2019` |
| `cloudwatch` | Cloudwatch (TODO - Info) | `any` | |
| `credentials` | Credentials (TODO - Info) | `any` | |
| `db_name` | Database Name | `string` | |
| `db_subnet_group_name` | Database Subnet Group Name | `string` | |
| `encryption` | Encryption (TODO - Info) | `any` | |
| `engine` | Engine | `string` | |
| `engine_version` | Engine Version | `string` | |
| `identifier` | Identifier | `string` | |
| `instance` | Instance (TODO - Info) | `any` | |
| `license_model` | License Model | `string` | |
| `maintenance` | Maintenance (TODO - Info) | `any` | |
| `monitoring_interval` | Monitoring Interval | `number` | `0` |
| `multi_az` | Enable MultiAZ | `bool` | `false` |
| `nchar_character_set_name` | NCHAR Character Set Name (Oracle) | `string` | |
| `option_group_name` | Option group to use for instances | `string` | |
| `parameter_group_name` | Parameter group to use for instances | `string` | |
| `performance_insights` | Performance Insights (TODO - Info) | `any` | |
| `port` | Port | `number` | |
| `replica` | Replica (TODO - Info) | `any` | |
| `security_groups_additional` | Security Groups (Additional) | `list(any)` | |
| `security_group_rules` | Security Group Rules (TODO - Info) | `any` | |
| `snapshot_identifier` | Database Snapshot ARN to create this database from | `string` | |
| `timeouts` | Timeouts (TODO - Info) | `any` | |
| `vpc_id` | VPC: ID | `string` | |

## Inputs (Details)
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `details.scope` | (Required) Scope Name - What does this object belong to? (Organization Name, Project, etc) | `string` | |
| `details.scope_abbr` | (Optional) Scope [Abbreviation](#Abbreviations) Override | `string` | |
| `details.purpose` | (Required) Purpose Name - What is the purpose or function of this object, or what does this object serve? | `string` | |
| `details.purpose_abbr` | (Optional) Purpose [Abbreviation](#Abbreviations) Override | `string` | |
| `details.environment` | (Required) Environment Name | `string` | |
| `details.environment_abbr` | (Optional) Environment [Abbreviation](#Abbreviations) Override | `string` | |
| `details.additional_tags` | (Optional) [Additional Tags](#Additional-Tags) for resources | `map` | `[]` |

***

## Outputs
All outputs from this module are mapped to a single output named `metadata` to make it easier to capture all of the relevant metadata that would be useful when referenced by other stacks (requires only a single output reference in your code, instead of dozens!)

| Name | Description |
|:-----|:------------|
| `details.scope.name` | Scope name |
| `details.scope.abbr` | Scope abbreviation |
| `details.scope.machine` | Scope machine-friendly abbreviation |
| `details.purpose.name` | Purpose name |
| `details.purpose.abbr` | Purpose abbreviation |
| `details.purpose.machine` | Purpose machine-friendly abbreviation |
| `details.environment.name` | Environment name |
| `details.environment.abbr` | Environment abbreviation |
| `details.environment.machine` | Environment machine-friendly abbreviation |
| `details.tags` | Map of tags applied to all resources |
| `cloudwatch.log_group.instance` | Cloudwatch - LogGroup: Instance |
| `cloudwatch.log_group.replica` | Cloudwatch - LogGroup: Replica |
| `iam.role.rds_enhanced_monitoring` | IAM - Role: RDS Enhanced Monitoring |
| `rds.instance` | RDS: Instance |
| `rds.replica` | RDS: Replica |
| `security_group` | Security Group |

***

## Notes

### Abbreviations
* When generating resource names, the module converts each identifier to a more 'machine-friendly' abbreviated format, removing all special characters, replacing spaces with underscores (_), and converting to lowercase. Example: 'Demo - Module' => 'demo_module'
* Not all resource names allow underscores. When those are encountered, the detail identifier will have the underscore removed (test_example => testexample) automatically. This machine-friendly abbreviation is referred to as 'machine' within the module.
* The abbreviations can be overridden by suppling the abbreviated names (ie: scope_abbr). This is useful when you have a long name and need the created resource names to be shorter. Some resources in AWS have shorter name constraints than others, or you may just prefer it shorter. NOTE: If specifying the Abbreviation, be sure to follow the convention of no spaces and no special characters (except for underscore), otherwise resoure creation may fail.

### Additional Tags
* You can specify additional tags for resources by adding to the `details.additional_tags` map.
```
additional_tags = {
  "Example"         = "Extra Tag"
  "Project"         = "Project Name"
  "CostCenter"      = "123456"
}
```

***

## Terraform Versions
Terraform ~> 1.11.0 is supported.

## Provider Versions
| Name | Version |
|------|---------|
| aws | `~> 5.93` |
