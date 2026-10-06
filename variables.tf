# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "additional_security_group_ids" {
  description = <<-EOT
    More security groups to attach to the database instance and its read replicas, beside the one the module creates, such as `["sg-0123456789abcdef0"]`. Use one when the database must open connections itself, for example to Amazon S3 or AWS Lambda: the module's group allows no outbound traffic.
  EOT
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for id in var.additional_security_group_ids : startswith(id, "sg-")])
    error_message = "Each entry in additional_security_group_ids must be a security group ID, such as sg-0123456789abcdef0."
  }
}

variable "backup" {
  description = <<-EOT
    Automated backups. AWS takes a daily snapshot and keeps transaction logs, so the database can be restored to any second within the retention period.

    - `retention_period` - (Optional) Days to keep automated backups, from `0` to `35`. Defaults to `7`. `0` turns automated backups off, which read replicas do not allow.
    - `window` - (Optional) The daily time range, in UTC, when backups are taken, such as `03:00-04:00`; at least 30 minutes, and not overlapping `maintenance.window`. Without it, AWS picks one.
  EOT
  type = object({
    retention_period = optional(number, 7)
    window           = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition     = try(var.backup.retention_period >= 0 && var.backup.retention_period <= 35 && floor(var.backup.retention_period) == var.backup.retention_period, false)
    error_message = "backup.retention_period must be a whole number from 0 to 35."
  }

  validation {
    condition     = var.backup.window == null || can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]-([01][0-9]|2[0-3]):[0-5][0-9]$", coalesce(var.backup.window, "-")))
    error_message = "backup.window must be a UTC time range such as 03:00-04:00."
  }
}

variable "ca_cert_identifier" {
  description = <<-EOT
    The certificate authority (CA) that signs the database's TLS certificate: `rds-ca-rsa2048-g1`, `rds-ca-rsa4096-g1` or `rds-ca-ecc384-g1`. Without it, AWS uses the Region's default, `rds-ca-rsa2048-g1` in most Regions. Clients that verify the server certificate need the matching CA bundle. Changing it later restarts the database.
  EOT
  type        = string
  default     = null
}

variable "cloudwatch_logs" {
  description = <<-EOT
    Database logs to publish to Amazon CloudWatch Logs. The module creates one log group per log type and instance, `/aws/rds/instance/<identifier>/<log type>`, before the database starts writing to it, so the retention below applies. With the default, `{}`, no logs are published.

    - `exports` - (Optional) The log types to publish. Each engine has its own: `postgresql` and `upgrade` (PostgreSQL); `audit`, `error`, `general` and `slowquery` (MySQL and MariaDB); `alert`, `audit`, `listener`, `trace` and `oemagent` (Oracle); `agent` and `error` (SQL Server); `diag.log` and `notify.log` (Db2). MySQL, MariaDB and PostgreSQL also have `iam-db-auth-error`. MySQL and MariaDB write `audit`, `general` and `slowquery` logs only when a parameter group turns them on.
    - `retention_in_days` - (Optional) Days to keep log events. Defaults to `7`. One of `1`, `3`, `5`, `7`, `14`, `30`, `60`, `90`, `120`, `150`, `180`, `365`, `400`, `545`, `731`, `1096`, `1827`, `2192`, `2557`, `2922`, `3288` or `3653`, or `0` to keep them forever.
    - `kms_key_id` - (Optional) ARN of a KMS key to encrypt the log groups with. Its key policy must let the CloudWatch Logs service principal for the Region use it. Without it, CloudWatch Logs encrypts them with its own key.
  EOT
  type = object({
    exports           = optional(list(string), [])
    retention_in_days = optional(number, 7)
    kms_key_id        = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for e in var.cloudwatch_logs.exports : contains(lookup({
        mariadb   = ["audit", "error", "general", "slowquery", "iam-db-auth-error"]
        mysql     = ["audit", "error", "general", "slowquery", "iam-db-auth-error"]
        postgres  = ["postgresql", "upgrade", "iam-db-auth-error"]
        oracle    = ["alert", "audit", "listener", "trace", "oemagent"]
        sqlserver = ["agent", "error"]
        db2       = ["diag.log", "notify.log"]
      }, split("-", var.engine)[0], []), e)
    ])
    error_message = "cloudwatch_logs.exports has a log type this engine does not have. See the input's description for each engine's log types."
  }

  validation {
    condition     = length(distinct(var.cloudwatch_logs.exports)) == length(var.cloudwatch_logs.exports)
    error_message = "cloudwatch_logs.exports lists a log type twice."
  }

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_logs.retention_in_days)
    error_message = "cloudwatch_logs.retention_in_days must be 0 (forever) or one of 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288 or 3653."
  }

  validation {
    condition     = var.cloudwatch_logs.kms_key_id == null || startswith(coalesce(var.cloudwatch_logs.kms_key_id, "-"), "arn:")
    error_message = "cloudwatch_logs.kms_key_id must be the ARN of a KMS key."
  }
}

variable "db_name" {
  description = <<-EOT
    The name of a database to create in the instance, such as `app`. Without it, no database is created beside the engine's own (PostgreSQL still has `postgres`). Not used with SQL Server, and ignored when restoring from `snapshot_identifier`. For Oracle it is the system ID (SID), up to 8 characters. Changing it later replaces the database instance and deletes its data.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.db_name == null || can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", coalesce(var.db_name, "-")))
    error_message = "db_name must start with a letter and contain only letters, digits and underscores, up to 63 characters."
  }

  validation {
    condition     = var.db_name == null || !startswith(var.engine, "sqlserver")
    error_message = "db_name cannot be set for SQL Server. Create databases after the instance is running."
  }
}

variable "db_subnet_group_name" {
  description = <<-EOT
    The name of the DB subnet group that places the database instance and its read replicas in subnets of `vpc_id`. Use private subnets in at least two Availability Zones. Choose it before you create the database: AWS can move an existing instance to another subnet group only in limited cases.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.db_subnet_group_name) != ""
    error_message = "db_subnet_group_name must not be empty."
  }
}

variable "deletion" {
  description = <<-EOT
    What protects the database from deletion, and what is kept when it is deleted.

    - `protection` - (Optional) Refuse to delete the database instance, and its read replicas, until this is set to `false` and applied. Defaults to `true`. Set it to `false` and apply before `terraform destroy`, or before any change that replaces the instance.
    - `skip_final_snapshot` - (Optional) Delete the database without a final snapshot. Defaults to `false`: a final snapshot named `<identifier>-final-<8 hex digits>` is taken and kept until you delete it.
    - `delete_automated_backups` - (Optional) Delete automated backups with the database. Defaults to `true`. With `false`, AWS keeps them until their retention period ends.
  EOT
  type = object({
    protection               = optional(bool, true)
    skip_final_snapshot      = optional(bool, false)
    delete_automated_backups = optional(bool, true)
  })
  default  = {}
  nullable = false
}

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-rds#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "engine" {
  description = <<-EOT
    The database engine: `postgres`, `mysql`, `mariadb`, `oracle-ee`, `oracle-ee-cdb`, `oracle-se2`, `oracle-se2-cdb`, `sqlserver-ee`, `sqlserver-se`, `sqlserver-ex`, `sqlserver-web`, `sqlserver-dev-ee`, `sqlserver-dev-se`, `db2-se`, `db2-ae` or `db2-ce`. Aurora engines need a cluster; use an Aurora module instead. Changing it later replaces the database instance and deletes its data.
  EOT
  type        = string
  nullable    = false

  validation {
    condition = contains([
      "postgres", "mysql", "mariadb",
      "oracle-ee", "oracle-ee-cdb", "oracle-se2", "oracle-se2-cdb",
      "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web", "sqlserver-dev-ee", "sqlserver-dev-se",
      "db2-se", "db2-ae", "db2-ce",
    ], var.engine)
    error_message = "engine must be one of postgres, mysql, mariadb, oracle-ee, oracle-ee-cdb, oracle-se2, oracle-se2-cdb, sqlserver-ee, sqlserver-se, sqlserver-ex, sqlserver-web, sqlserver-dev-ee, sqlserver-dev-se, db2-se, db2-ae or db2-ce."
  }
}

variable "engine_lifecycle_support" {
  description = <<-EOT
    What happens when the engine's major version reaches the end of standard support, for MySQL and PostgreSQL. `open-source-rds-extended-support`, the AWS default, keeps the version running under Amazon RDS Extended Support, which AWS bills for each vCPU-hour. `open-source-rds-extended-support-disabled` has AWS upgrade the database to a supported major version instead, with no Extended Support charge. Without a value, AWS uses its default.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.engine_lifecycle_support == null || (contains(["open-source-rds-extended-support", "open-source-rds-extended-support-disabled"], coalesce(var.engine_lifecycle_support, "-")) && contains(["mysql", "postgres"], var.engine))
    error_message = "engine_lifecycle_support must be open-source-rds-extended-support or open-source-rds-extended-support-disabled, and can be set only for mysql and postgres."
  }
}

variable "engine_version" {
  description = <<-EOT
    The engine version. Give the major version only, such as `17` for PostgreSQL or `8.4` for MySQL: AWS picks the newest minor version, and the minor upgrades AWS applies later (see `maintenance.auto_minor_version_upgrade`) do not show as changes. With a full version such as `17.6`, every plan after AWS upgrades the minor version tries to go back to it, and fails. Without a value, AWS uses the engine's default version.

    A higher major version upgrades the database in place, and needs `maintenance.allow_major_version_upgrade = true`, and usually a parameter group for the new version.
  EOT
  type        = string
  default     = null
}

variable "iam_database_authentication_enabled" {
  description = <<-EOT
    Let database users sign in with an AWS Identity and Access Management (IAM) authentication token instead of a password. Supported by PostgreSQL, MySQL and MariaDB, and on by default for them; each database user must still be set up for it inside the database. Without a value, it is on for those engines and off for the others.
  EOT
  type        = bool
  default     = null

  validation {
    condition     = var.iam_database_authentication_enabled != true || contains(["postgres", "mysql", "mariadb"], var.engine)
    error_message = "iam_database_authentication_enabled can be true only for postgres, mysql and mariadb."
  }
}

variable "identifier" {
  description = <<-EOT
    The name of the database instance, such as `app-production`: 1 to 63 lowercase letters, digits and hyphens, starting with a letter, with no two hyphens in a row and no hyphen at the end. It must be unique among the account's instances in the Region. Read replicas are named `<identifier>-replica-<n>`, so with replicas it can have at most 52 characters.

    AWS renames the instance in place when it changes; its endpoint address changes with it. The module's log groups are named after it, so a rename replaces them, and deletes the old ones with their log events.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.identifier)) && !strcontains(var.identifier, "--") && !endswith(var.identifier, "-")
    error_message = "identifier must be 1 to 63 lowercase letters, digits and hyphens, start with a letter, and have no two hyphens in a row and no hyphen at the end."
  }

  validation {
    condition     = var.read_replicas.count == 0 || length(var.identifier) <= 52
    error_message = "With read replicas, identifier can have at most 52 characters, so that <identifier>-replica-<n> fits in 63."
  }
}

variable "instance_class" {
  description = <<-EOT
    The instance class, which sets the CPU and memory, such as `db.t4g.micro` or `db.m7g.large`. Not every class is offered for every engine and version in every Region; `aws rds describe-orderable-db-instance-options` lists them. Changing it later resizes the instance in place, with a short outage (or a failover, with `multi_az`).
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = startswith(var.instance_class, "db.")
    error_message = "instance_class must be an RDS instance class, such as db.t4g.micro."
  }
}

variable "kms_key_id" {
  description = <<-EOT
    ARN of the AWS Key Management Service (KMS) key that encrypts the database's storage, automated backups, snapshots, read replicas and Performance Insights data. The database is always encrypted; without a key, RDS uses the AWS managed key `aws/rds`, which cannot be shared with other accounts.

    Changing the key later, including setting one, replaces the database instance and deletes its data: RDS cannot change the key of an existing instance.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null || startswith(coalesce(var.kms_key_id, "-"), "arn:")
    error_message = "kms_key_id must be the ARN of a KMS key, such as arn:aws:kms:us-east-1:123456789012:key/<key id>."
  }
}

variable "license_model" {
  description = <<-EOT
    The license model, for engines that have more than one: `license-included` or `bring-your-own-license` (Oracle, Db2), `marketplace-license` (Db2 through AWS Marketplace). Without it, AWS uses the engine's default.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.license_model == null || contains(["license-included", "bring-your-own-license", "marketplace-license", "general-public-license", "postgresql-license"], coalesce(var.license_model, "-"))
    error_message = "license_model must be license-included, bring-your-own-license, marketplace-license, general-public-license or postgresql-license."
  }
}

variable "maintenance" {
  description = <<-EOT
    When and how the database is changed.

    - `window` - (Optional) The weekly time range, in UTC, for maintenance and for changes not applied immediately, such as `sun:05:00-sun:06:00`; at least 30 minutes. Without it, AWS picks one.
    - `auto_minor_version_upgrade` - (Optional) Let AWS apply minor engine versions during the maintenance window. Defaults to `true`.
    - `allow_major_version_upgrade` - (Optional) Allow a change of `engine_version` to a higher major version. Defaults to `false`.
    - `apply_immediately` - (Optional) Apply changes as soon as they are made instead of in the next maintenance window. Defaults to `false`. Changes such as a new `instance_class` restart the database. Until a deferred change is applied, every plan shows it again.
  EOT
  type = object({
    window                      = optional(string)
    auto_minor_version_upgrade  = optional(bool, true)
    allow_major_version_upgrade = optional(bool, false)
    apply_immediately           = optional(bool, false)
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.maintenance.window == null || can(regex("^(mon|tue|wed|thu|fri|sat|sun):([01][0-9]|2[0-3]):[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):([01][0-9]|2[0-3]):[0-5][0-9]$", coalesce(var.maintenance.window, "-")))
    error_message = "maintenance.window must be a lowercase UTC range such as sun:05:00-sun:06:00."
  }
}

variable "master_user" {
  description = <<-EOT
    The database's master user. RDS creates its password and keeps it in AWS Secrets Manager, where RDS rotates it every 7 days; the module never sees it, so it is not in the Terraform state. The secret's ARN is in the `metadata` output, at `db_instance.master_user_secret[0].secret_arn`.

    With `read_replicas`, on any engine but SQL Server and Db2, AWS does not allow that. The module then creates a 30-character password itself and keeps it, with the user name, in a Secrets Manager secret of its own, at `metadata.secretsmanager_secret.arn`. That password is in the Terraform state, so protect the state, and it is not rotated. Adding the first replica to an existing database, or removing the last, switches between the two, and the password changes; see the README for two traps when removing the last replica.

    - `username` - (Optional) The master user's name, such as `dbadmin`: a letter, then letters, digits and underscores. Required unless `snapshot_identifier` is set, when the snapshot's master user is kept. Each engine has its own length limit and reserved words, such as `rdsadmin`. Changing it later has no effect: the module ignores changes to it, because AWS can change it only by replacing the database.
    - `secret_kms_key_id` - (Optional) The KMS key that encrypts the secret, either one: a key ID, key ARN, alias name or alias ARN. Without it, Secrets Manager uses the AWS managed key `aws/secretsmanager`.
  EOT
  type = object({
    username          = optional(string)
    secret_kms_key_id = optional(string)
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.master_user.username != null || var.snapshot_identifier != null
    error_message = "master_user.username is required, unless snapshot_identifier is set."
  }

  validation {
    condition     = var.master_user.username == null || can(regex("^[A-Za-z][A-Za-z0-9_]{0,127}$", coalesce(var.master_user.username, "-")))
    error_message = "master_user.username must start with a letter and contain only letters, digits and underscores."
  }
}

variable "monitoring_interval" {
  description = <<-EOT
    Seconds between Enhanced Monitoring samples of the operating system, sent to CloudWatch Logs in the `RDSOSMetrics` log group: `1`, `5`, `10`, `15`, `30` or `60`, or `0` for none. Defaults to `0`. Enhanced Monitoring is billed as CloudWatch Logs. With a value above `0`, the module creates the IAM role RDS uses to send the metrics, named `rds-monitoring-` followed by a unique suffix.
  EOT
  type        = number
  default     = 0
  nullable    = false

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be 0, 1, 5, 10, 15, 30 or 60."
  }
}

variable "multi_az" {
  description = <<-EOT
    Keep a standby copy of the database in another Availability Zone, which RDS fails over to when the primary or its zone fails. It about doubles the instance and storage cost. Defaults to `false`. Turning it on later happens in place, without an outage.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "nchar_character_set_name" {
  description = <<-EOT
    The national character set, for Oracle only: `AL16UTF16` (the default) or `UTF8`. Changing it later replaces the database instance.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.nchar_character_set_name == null || startswith(var.engine, "oracle")
    error_message = "nchar_character_set_name can be set only for Oracle engines."
  }
}

variable "option_group_name" {
  description = <<-EOT
    The name of an option group to turn on engine features, such as Oracle Transparent Data Encryption or SQL Server native backups. Without it, AWS uses the engine version's default option group.
  EOT
  type        = string
  default     = null
}

variable "parameter_group_name" {
  description = <<-EOT
    The name of a DB parameter group for engine settings, such as `rds.force_ssl` or the MySQL slow query log. It must be for the engine's parameter group family, such as `postgres17`. Without it, AWS uses the family's default parameter group, which cannot be changed. Changing it later needs a restart before the new settings apply.
  EOT
  type        = string
  default     = null
}

variable "performance_insights" {
  description = <<-EOT
    Performance Insights, which records database load and the queries causing it. The first 7 days of history are free; longer retention is billed.

    - `enabled` - (Optional) Turn it on. Defaults to `false`. Not every engine and instance class supports it: MySQL and MariaDB on `db.t3` and `db.t4g` micro and small classes do not, and AWS refuses to create such an instance with it on. `aws rds describe-orderable-db-instance-options` shows `SupportsPerformanceInsights` for each.
    - `retention_period` - (Optional) Days of history to keep: `7`, `731`, or a multiple of `31` up to `713`. Defaults to `7`.

    The data is encrypted with `kms_key_id`, or with `aws/rds` without it. Once Performance Insights has been on with one key, it cannot be turned on with another.
  EOT
  type = object({
    enabled          = optional(bool, false)
    retention_period = optional(number, 7)
  })
  default  = {}
  nullable = false

  validation {
    condition     = contains(concat([7, 731], [for m in range(1, 24) : m * 31]), var.performance_insights.retention_period)
    error_message = "performance_insights.retention_period must be 7, 731, or a multiple of 31 up to 713."
  }
}

variable "port" {
  description = <<-EOT
    The port the database listens on, from `1150` to `65535`. Without it, the module uses the engine's default: `5432` for PostgreSQL, `3306` for MySQL and MariaDB, `1521` for Oracle, `1433` for SQL Server and `50000` for Db2. The security group allows this port. Changing it later restarts the database.
  EOT
  type        = number
  default     = null

  validation {
    condition     = var.port == null || try(var.port >= 1150 && var.port <= 65535 && floor(var.port) == var.port, false)
    error_message = "port must be a whole number from 1150 to 65535."
  }
}

variable "publicly_accessible" {
  description = <<-EOT
    Give the database a public IP address, so its endpoint resolves to it from outside the VPC. Defaults to `false`. It also needs public subnets in `db_subnet_group_name` and a `security_group_ingress` source outside the VPC. Keep databases private; reach them through the VPC instead.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "read_replicas" {
  description = <<-EOT
    Read replicas in the same Region: copies of the database that RDS keeps up to date asynchronously, for read-only queries. They are named `<identifier>-replica-1`, `-replica-2` and so on, and use the primary's subnet group, security groups, parameter and option groups, port, Performance Insights, Enhanced Monitoring and log settings.

    - `count` - (Optional) How many, from `0` to `15`. Defaults to `0`. Lowering it deletes the replicas with the highest numbers.
    - `instance_class` - (Optional) The replicas' instance class. Defaults to `instance_class`.
    - `multi_az` - (Optional) Give each replica a standby in another Availability Zone. Defaults to `false`.

    Replicas need automated backups on the primary (`backup.retention_period` above `0`). Oracle needs Enterprise Edition with an Active Data Guard license, and SQL Server needs Enterprise Edition. Except on SQL Server and Db2, AWS does not create replicas of a database whose password RDS manages, so with replicas the module manages the master password instead, and it is in the Terraform state (see `master_user`).
  EOT
  type = object({
    count          = optional(number, 0)
    instance_class = optional(string)
    multi_az       = optional(bool, false)
  })
  default  = {}
  nullable = false

  validation {
    condition     = try(var.read_replicas.count >= 0 && var.read_replicas.count <= 15 && floor(var.read_replicas.count) == var.read_replicas.count, false)
    error_message = "read_replicas.count must be a whole number from 0 to 15."
  }

  validation {
    condition     = var.read_replicas.instance_class == null || startswith(coalesce(var.read_replicas.instance_class, "-"), "db.")
    error_message = "read_replicas.instance_class must be an RDS instance class, such as db.t4g.micro."
  }

  validation {
    condition     = var.read_replicas.count == 0 || var.backup.retention_period > 0
    error_message = "Read replicas need automated backups on the primary: set backup.retention_period above 0."
  }
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the database and everything else in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.
  EOT
  type        = string
  default     = null
}

variable "security_group_ingress" {
  description = <<-EOT
    Who can reach the database over the network. The module creates a security group for the database instance and its read replicas that allows the database port (TCP) from each source listed here, and from nothing else. It allows no outbound traffic: the database only answers connections, and security groups let replies out on their own. With the default, `{}`, no client can connect. The keys are names you choose; they only identify each rule, so a security group created in the same configuration can be used.

    Each source takes exactly one of:

    - `cidr_ipv4` - An IPv4 range, such as `10.0.0.0/16`.
    - `cidr_ipv6` - An IPv6 range, such as `2600:1f18:1234:5600::/56`.
    - `security_group_id` - A security group whose members may connect, such as the group of your application servers.
    - `prefix_list_id` - A managed prefix list of ranges.

    and optionally:

    - `description` - (Optional) What the source is. Defaults to the key.
  EOT
  type = map(object({
    cidr_ipv4         = optional(string)
    cidr_ipv6         = optional(string)
    security_group_id = optional(string)
    prefix_list_id    = optional(string)
    description       = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for s in values(var.security_group_ingress) :
      length([for v in [s.cidr_ipv4, s.cidr_ipv6, s.security_group_id, s.prefix_list_id] : v if v != null]) == 1
    ])
    error_message = "Each security_group_ingress entry needs exactly one of cidr_ipv4, cidr_ipv6, security_group_id or prefix_list_id."
  }

  validation {
    condition = alltrue([
      for s in values(var.security_group_ingress) :
      (s.cidr_ipv4 == null || can(cidrnetmask(s.cidr_ipv4))) && (s.cidr_ipv6 == null || (can(cidrhost(s.cidr_ipv6, 0)) && strcontains(coalesce(s.cidr_ipv6, "-"), ":")))
    ])
    error_message = "security_group_ingress: cidr_ipv4 must be an IPv4 range such as 10.0.0.0/16, and cidr_ipv6 an IPv6 range such as 2600:1f18:1234:5600::/56."
  }
}

variable "snapshot_identifier" {
  description = <<-EOT
    Create the database from this DB snapshot: its identifier, or its ARN for a snapshot shared from another account. The snapshot's engine, master user, database name and storage size are used. Only read when the database is created; changing it later has no effect. A snapshot encrypted with another account's key, or with `aws/rds`, must first be copied with a key this account can use.
  EOT
  type        = string
  default     = null
}

variable "storage" {
  description = <<-EOT
    The database's storage.

    - `type` - (Optional) `gp3`, the default (General Purpose SSD), `gp2`, `io1` or `io2` (Provisioned IOPS SSD), or `standard` (magnetic, previous generation).
    - `allocated` - (Optional) Size in GiB. Defaults to `20`, the smallest most engines allow; when restoring from `snapshot_identifier`, defaults to the snapshot's size. Storage can grow later in place, but never shrink, and after a change AWS allows the next one only after 6 hours.
    - `max_allocated` - (Optional) Turn on storage autoscaling: RDS grows the storage on its own, up to this many GiB, when it runs low. Must be more than `allocated`. Changes made this way do not show in plans.
    - `iops` - (Optional) Provisioned I/O operations per second. Required for `io1` and `io2`. With `gp3`, AWS accepts it only above a size that depends on the engine (400 GiB for PostgreSQL, MySQL and MariaDB); below it, gp3 includes 3,000 IOPS.
    - `throughput` - (Optional) Provisioned throughput in MiB/s, for `gp3` only, with the same size limit as `iops`.
  EOT
  type = object({
    type          = optional(string, "gp3")
    allocated     = optional(number)
    max_allocated = optional(number)
    iops          = optional(number)
    throughput    = optional(number)
  })
  default  = {}
  nullable = false

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2", "standard"], var.storage.type)
    error_message = "storage.type must be gp3, gp2, io1, io2 or standard."
  }

  validation {
    condition     = var.storage.allocated == null || try(var.storage.allocated >= 5 && floor(var.storage.allocated) == var.storage.allocated, false)
    error_message = "storage.allocated must be a whole number of GiB."
  }

  validation {
    condition     = var.storage.max_allocated == null || try(var.storage.max_allocated > coalesce(var.storage.allocated, 20), false)
    error_message = "storage.max_allocated must be more than storage.allocated."
  }

  validation {
    condition     = var.storage.iops == null || contains(["gp3", "io1", "io2"], var.storage.type)
    error_message = "storage.iops can be set only for gp3, io1 and io2."
  }

  validation {
    condition     = var.storage.iops != null || !contains(["io1", "io2"], var.storage.type)
    error_message = "storage.iops is required for io1 and io2."
  }

  validation {
    condition     = var.storage.throughput == null || var.storage.type == "gp3"
    error_message = "storage.throughput can be set only for gp3."
  }
}

variable "timeouts" {
  description = <<-EOT
    How long Terraform waits for the database instance and each read replica.

    - `create` - (Optional) Defaults to `180m`. Restores from large snapshots can take hours.
    - `update` - (Optional) Defaults to `120m`.
    - `delete` - (Optional) Defaults to `120m`.
  EOT
  type = object({
    create = optional(string, "180m")
    update = optional(string, "120m")
    delete = optional(string, "120m")
  })
  default  = {}
  nullable = false
}

variable "vpc_id" {
  description = <<-EOT
    The ID of the VPC the database is in, such as `vpc-0123456789abcdef0`: the VPC of `db_subnet_group_name`. The module creates the database's security group in it.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = startswith(var.vpc_id, "vpc-")
    error_message = "vpc_id must be a VPC ID, such as vpc-0123456789abcdef0."
  }
}
