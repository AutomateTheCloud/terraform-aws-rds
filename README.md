# Terraform module for Amazon RDS databases

Creates an Amazon Relational Database Service (RDS) database instance for PostgreSQL, MySQL, MariaDB, Oracle, SQL Server or Db2, with a security group that controls which clients can reach it. Optional settings cover read replicas, a standby in a second Availability Zone (Multi-AZ), storage autoscaling, backups, maintenance, logs in Amazon CloudWatch, Enhanced Monitoring and Performance Insights.

The defaults are the settings most databases should have. A database created with only the required inputs is private, encrypted, protected from deletion, backed up for 7 days, and cannot be reached over the network until you allow a source. RDS creates the master password and keeps it in AWS Secrets Manager, so it does not appear in the Terraform state (read replicas change that; see [The master password](https://github.com/AutomateTheCloud/terraform-aws-rds#the-master-password)).

## What it configures

| Setting | Default | Input |
|---|---|---|
| Encryption at rest | Always on, with the AWS managed key `aws/rds` | `kms_key_id` |
| Master password | Created by RDS, kept and rotated in Secrets Manager; with read replicas, created by the module and kept in a secret it creates | `master_user` |
| Network access | None: no client can connect | `security_group_ingress` |
| Outbound traffic | None | `additional_security_group_ids` |
| Public IP address | None | `publicly_accessible` |
| IAM database authentication | On for PostgreSQL, MySQL and MariaDB | `iam_database_authentication_enabled` |
| Deletion protection | On | `deletion.protection` |
| Final snapshot when deleted | Taken | `deletion.skip_final_snapshot` |
| Automated backups | Kept 7 days | `backup` |
| Storage | 20 GiB of gp3, no autoscaling | `storage` |
| Multi-AZ standby | Off | `multi_az` |
| Read replicas | None | `read_replicas` |
| Minor version upgrades | Applied by AWS in the maintenance window | `maintenance` |
| Performance Insights | Off | `performance_insights` |
| Enhanced Monitoring | Off | `monitoring_interval` |
| Logs in CloudWatch | None | `cloudwatch_logs` |

## Usage

```hcl
module "rds" {
  source  = "AutomateTheCloud/rds/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "App Data"
    environment = "Production"
  }

  identifier           = "app-production"
  engine               = "postgres"
  engine_version       = "17"
  instance_class       = "db.t4g.small"
  vpc_id               = "vpc-0123456789abcdef0"
  db_subnet_group_name = "app-private"
  master_user          = { username = "dbadmin" }

  security_group_ingress = {
    app = { security_group_id = "sg-0123456789abcdef0", description = "Application servers" }
  }
}
```

`details`, `identifier`, `engine`, `instance_class`, `vpc_id`, `db_subnet_group_name` and `master_user.username` are the only required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags on every resource.

Clients connect to `module.rds.metadata.db_instance.address` on `module.rds.metadata.db_instance.port`. The master password is in the Secrets Manager secret at `module.rds.metadata.db_instance.master_user_secret[0].secret_arn`.

The module uses your default `aws` provider and creates everything in that provider's Region. To create the database somewhere else without configuring another provider, set `region`:

```hcl
module "rds_us_west_2" {
  source  = "AutomateTheCloud/rds/aws"
  version = "~> 1.0"

  region               = "us-west-2"
  details              = { scope = "Automate the Cloud", purpose = "App Data", environment = "Production" }
  identifier           = "app-production"
  engine               = "postgres"
  instance_class       = "db.t4g.small"
  vpc_id               = "vpc-0abcdef0123456789"
  db_subnet_group_name = "app-private"
  master_user          = { username = "dbadmin" }
}
```

The VPC and subnet group must be in that Region too.

To use a provider configured for another account, pass it explicitly with `providers = { aws = aws.other_account }`.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the database belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "App Data"           # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a database in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the database, its key, its network and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "App Data"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "app_database" {
  source  = "AutomateTheCloud/rds/aws"
  version = "~> 1.0"

  details              = local.details
  identifier           = "app-production"
  engine               = "postgres"
  instance_class       = "db.t4g.small"
  vpc_id               = "vpc-0123456789abcdef0"
  db_subnet_group_name = "app-private"
  master_user          = { username = "dbadmin" }
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`App Data` becomes `app_data`), and `machine`, lowercase letters and numbers only (`appdata`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.app_database.metadata.db_instance.address` for the host name clients connect to, or `module.app_database.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`, given a VPC and private subnets.

- [Basic database](https://github.com/AutomateTheCloud/terraform-aws-rds/tree/main/examples/basic): a private, encrypted PostgreSQL database that anything in the VPC can reach.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-rds/tree/main/examples/complete): most of the module's options, with a customer managed key, a Multi-AZ standby, a read replica, and access from one security group.

## Things to know

### The master password

By default the module sets `manage_master_user_password`: RDS creates the master user's password, stores it in a Secrets Manager secret it manages, and rotates it every 7 days. Terraform never sees the password, so it is not in the state, the plan or the outputs. Applications and people read it from the secret, whose ARN is in `metadata.db_instance.master_user_secret[0].secret_arn`:

```shell
aws secretsmanager get-secret-value --secret-id '<secret ARN>' --query SecretString --output text
```

Because the password changes on rotation, applications should read the secret when they connect, rather than keep a copy. For an application, create its own database user, and grant it only what it needs, rather than using the master user. With IAM database authentication, on by default for PostgreSQL, MySQL and MariaDB, that user can sign in with a short-lived token instead of a password; see [IAM database authentication](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html).

**With read replicas,** on any engine but SQL Server and Db2, AWS does not allow a password RDS manages: it refuses to create the replicas. The module then creates a 30-character password itself, sets it on the database, and keeps it in a Secrets Manager secret it creates, with the same `username` and `password` keys, at `metadata.secretsmanager_secret.arn`. That password is not rotated, and it is in the Terraform state, so keep the state in an encrypted backend that only administrators can read. Adding the first replica to an existing database, or removing the last one, switches between the two secrets, and the master password changes.

Removing the last replica has two traps, both seen in AWS with provider 6.67.0:

- RDS is still updating the primary right after deleting the replica, so the apply can fail with `InvalidDBInstanceState`. The module's secret is already deleted by then, and the database keeps that password until the next apply succeeds; run `terraform apply` again once the instance shows `available`. The deleted secret can be restored for 7 days with `aws secretsmanager restore-secret`.
- The AWS provider does not pass `master_user.secret_kms_key_id` when it hands the password back to RDS, so the new secret is encrypted with `aws/secretsmanager`, and no plan shows the difference. `metadata.db_instance.master_user_secret[0].kms_key_id` shows the key actually used. AWS cannot change that key later; to use your key, turn management off and on again with the AWS CLI (`aws rds modify-db-instance --no-manage-master-user-password --master-user-password ...`, then `--manage-master-user-password --master-user-secret-kms-key-id <key>`).

The master user's name cannot be changed later: AWS would have to replace the database, so the module ignores changes to `master_user.username`.

### Deleting a database

Deletion protection is on by default, so `terraform destroy`, and any change that would replace the instance, fails until you set `deletion.protection = false` and apply. When the database is deleted, RDS takes a final snapshot named `<identifier>-final-<8 hex digits>`, unless `deletion.skip_final_snapshot` is `true`. The snapshot is kept, and billed, until you delete it; restore from it with `snapshot_identifier`.

With read replicas, RDS can still be updating the primary when the replicas are gone, and the destroy then fails with `InvalidDBInstanceState: Cannot create a snapshot because the database instance ... is not currently in the available state`. Run `terraform destroy` again once the instance shows `available`.

### Settings that replace the database

AWS cannot change a database's engine, encryption key, `db_name` or Oracle national character set. Changing `engine`, `kms_key_id` (including setting one later), `db_name` or `nchar_character_set_name` replaces the instance, and its data is deleted, after a final snapshot unless you skipped it. Deletion protection stops such a plan at apply. Most other settings, including `identifier`, `instance_class`, storage, `multi_az`, backups and the security group's sources, change in place.

### Engine versions and upgrades

Give `engine_version` as a major version only, such as `17` for PostgreSQL or `8.4` for MySQL. AWS picks the newest minor version, applies later minor versions in the maintenance window (`maintenance.auto_minor_version_upgrade`), and the plan stays clean. A full version such as `17.6` makes the first plan after an automatic upgrade try to go back, which AWS refuses.

To upgrade to a new major version, set `engine_version` to it, set `maintenance.allow_major_version_upgrade = true`, and pass a parameter group for the new version's family if you use your own. The upgrade happens in place, with downtime, and read replicas are upgraded with the primary. AWS reports the new minor version and the new default option group only after the apply has saved the instance, so the first plan afterwards shows `metadata` changing; applying that plan, which changes no resources, clears it.

When a major version reaches the end of standard support, AWS keeps MySQL and PostgreSQL running under [RDS Extended Support](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/extended-support.html), billed per vCPU-hour, unless `engine_lifecycle_support = "open-source-rds-extended-support-disabled"`.

### Changes that wait for the maintenance window

With `maintenance.apply_immediately = false`, the default, RDS applies some changes, such as a new instance class, in the next maintenance window. Until then, every plan shows the change again, because AWS still reports the old value. Set `apply_immediately = true` to apply changes at once; changes such as a new instance class then restart the database straight away.

### Network access

The module's security group allows the database port, over TCP, from the sources in `security_group_ingress`, and nothing else. It has no outbound rules. Databases only answer connections, so this is enough for clients; features that make the database open connections itself, such as the PostgreSQL `aws_s3` and `aws_lambda` extensions or SQL Server and Oracle integrations with Amazon S3, need a security group with outbound rules in `additional_security_group_ids`.

Keep databases private. `publicly_accessible = true` gives the database a public IP address, but it is reachable only from sources in `security_group_ingress`, and only in public subnets.

### Storage

Storage can grow but never shrink, and after a change AWS allows the next one only after six hours. With `storage.max_allocated` set, RDS grows the storage on its own when it runs low, and the AWS provider does not show the larger size as a change. For the IOPS and throughput that gp3 storage includes at each size, and when `storage.iops` and `storage.throughput` can raise them, see [gp3 storage](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html#gp3-storage) in the RDS documentation.

### Read replicas

Read replicas are in the same Region as the primary, use its subnet group, security groups and encryption key, and are kept up to date asynchronously, so they can lag behind. Each replica is a separate instance, billed like one. Replicas need automated backups on the primary. Lowering `read_replicas.count` deletes the replicas with the highest numbers, without a final snapshot.

### Logs and monitoring

For each log type in `cloudwatch_logs.exports`, the module creates the log group `/aws/rds/instance/<identifier>/<log type>` for the primary and each replica, with the retention you choose, before RDS starts writing to it. Destroying the module deletes those log groups and their events.

Enhanced Monitoring sends operating system metrics to the `RDSOSMetrics` log group, which RDS creates and the module does not manage. The module creates the IAM role RDS uses for it; its trust policy allows only RDS acting for your account.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-rds/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-rds/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

- <a name="requirement_random"></a> [random](#requirement_random) (>= 3.0)

### Required Inputs

The following input variables are required:

#### <a name="input_db_subnet_group_name"></a> [db_subnet_group_name](#input_db_subnet_group_name)

Description: The name of the DB subnet group that places the database instance and its read replicas in subnets of `vpc_id`. Use private subnets in at least two Availability Zones. Choose it before you create the database: AWS can move an existing instance to another subnet group only in limited cases.

Type: `string`

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-rds#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_engine"></a> [engine](#input_engine)

Description: The database engine: `postgres`, `mysql`, `mariadb`, `oracle-ee`, `oracle-ee-cdb`, `oracle-se2`, `oracle-se2-cdb`, `sqlserver-ee`, `sqlserver-se`, `sqlserver-ex`, `sqlserver-web`, `sqlserver-dev-ee`, `sqlserver-dev-se`, `db2-se`, `db2-ae` or `db2-ce`. Aurora engines need a cluster; use an Aurora module instead. Changing it later replaces the database instance and deletes its data.

Type: `string`

#### <a name="input_identifier"></a> [identifier](#input_identifier)

Description: The name of the database instance, such as `app-production`: 1 to 63 lowercase letters, digits and hyphens, starting with a letter, with no two hyphens in a row and no hyphen at the end. It must be unique among the account's instances in the Region. Read replicas are named `<identifier>-replica-<n>`, so with replicas it can have at most 52 characters.

AWS renames the instance in place when it changes; its endpoint address changes with it. The module's log groups are named after it, so a rename replaces them, and deletes the old ones with their log events.

Type: `string`

#### <a name="input_instance_class"></a> [instance_class](#input_instance_class)

Description: The instance class, which sets the CPU and memory, such as `db.t4g.micro` or `db.m7g.large`. Not every class is offered for every engine and version in every Region; `aws rds describe-orderable-db-instance-options` lists them. Changing it later resizes the instance in place, with a short outage (or a failover, with `multi_az`).

Type: `string`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: The ID of the VPC the database is in, such as `vpc-0123456789abcdef0`: the VPC of `db_subnet_group_name`. The module creates the database's security group in it.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_additional_security_group_ids"></a> [additional_security_group_ids](#input_additional_security_group_ids)

Description: More security groups to attach to the database instance and its read replicas, beside the one the module creates, such as `["sg-0123456789abcdef0"]`. Use one when the database must open connections itself, for example to Amazon S3 or AWS Lambda: the module's group allows no outbound traffic.

Type: `list(string)`

Default: `[]`

#### <a name="input_backup"></a> [backup](#input_backup)

Description: Automated backups. AWS takes a daily snapshot and keeps transaction logs, so the database can be restored to any second within the retention period.

- `retention_period` - (Optional) Days to keep automated backups, from `0` to `35`. Defaults to `7`. `0` turns automated backups off, which read replicas do not allow.
- `window` - (Optional) The daily time range, in UTC, when backups are taken, such as `03:00-04:00`; at least 30 minutes, and not overlapping `maintenance.window`. Without it, AWS picks one.

Type:

```hcl
object({
    retention_period = optional(number, 7)
    window           = optional(string)
  })
```

Default: `{}`

#### <a name="input_ca_cert_identifier"></a> [ca_cert_identifier](#input_ca_cert_identifier)

Description: The certificate authority (CA) that signs the database's TLS certificate: `rds-ca-rsa2048-g1`, `rds-ca-rsa4096-g1` or `rds-ca-ecc384-g1`. Without it, AWS uses the Region's default, `rds-ca-rsa2048-g1` in most Regions. Clients that verify the server certificate need the matching CA bundle. Changing it later restarts the database.

Type: `string`

Default: `null`

#### <a name="input_cloudwatch_logs"></a> [cloudwatch_logs](#input_cloudwatch_logs)

Description: Database logs to publish to Amazon CloudWatch Logs. The module creates one log group per log type and instance, `/aws/rds/instance/<identifier>/<log type>`, before the database starts writing to it, so the retention below applies. With the default, `{}`, no logs are published.

- `exports` - (Optional) The log types to publish. Each engine has its own: `postgresql` and `upgrade` (PostgreSQL); `audit`, `error`, `general` and `slowquery` (MySQL and MariaDB); `alert`, `audit`, `listener`, `trace` and `oemagent` (Oracle); `agent` and `error` (SQL Server); `diag.log` and `notify.log` (Db2). MySQL, MariaDB and PostgreSQL also have `iam-db-auth-error`. MySQL and MariaDB write `audit`, `general` and `slowquery` logs only when a parameter group turns them on.
- `retention_in_days` - (Optional) Days to keep log events. Defaults to `7`. One of `1`, `3`, `5`, `7`, `14`, `30`, `60`, `90`, `120`, `150`, `180`, `365`, `400`, `545`, `731`, `1096`, `1827`, `2192`, `2557`, `2922`, `3288` or `3653`, or `0` to keep them forever.
- `kms_key_id` - (Optional) ARN of a KMS key to encrypt the log groups with. Its key policy must let the CloudWatch Logs service principal for the Region use it. Without it, CloudWatch Logs encrypts them with its own key.

Type:

```hcl
object({
    exports           = optional(list(string), [])
    retention_in_days = optional(number, 7)
    kms_key_id        = optional(string)
  })
```

Default: `{}`

#### <a name="input_db_name"></a> [db_name](#input_db_name)

Description: The name of a database to create in the instance, such as `app`. Without it, no database is created beside the engine's own (PostgreSQL still has `postgres`). Not used with SQL Server, and ignored when restoring from `snapshot_identifier`. For Oracle it is the system ID (SID), up to 8 characters. Changing it later replaces the database instance and deletes its data.

Type: `string`

Default: `null`

#### <a name="input_deletion"></a> [deletion](#input_deletion)

Description: What protects the database from deletion, and what is kept when it is deleted.

- `protection` - (Optional) Refuse to delete the database instance, and its read replicas, until this is set to `false` and applied. Defaults to `true`. Set it to `false` and apply before `terraform destroy`, or before any change that replaces the instance.
- `skip_final_snapshot` - (Optional) Delete the database without a final snapshot. Defaults to `false`: a final snapshot named `<identifier>-final-<8 hex digits>` is taken and kept until you delete it.
- `delete_automated_backups` - (Optional) Delete automated backups with the database. Defaults to `true`. With `false`, AWS keeps them until their retention period ends.

Type:

```hcl
object({
    protection               = optional(bool, true)
    skip_final_snapshot      = optional(bool, false)
    delete_automated_backups = optional(bool, true)
  })
```

Default: `{}`

#### <a name="input_engine_lifecycle_support"></a> [engine_lifecycle_support](#input_engine_lifecycle_support)

Description: What happens when the engine's major version reaches the end of standard support, for MySQL and PostgreSQL. `open-source-rds-extended-support`, the AWS default, keeps the version running under Amazon RDS Extended Support, which AWS bills for each vCPU-hour. `open-source-rds-extended-support-disabled` has AWS upgrade the database to a supported major version instead, with no Extended Support charge. Without a value, AWS uses its default.

Type: `string`

Default: `null`

#### <a name="input_engine_version"></a> [engine_version](#input_engine_version)

Description: The engine version. Give the major version only, such as `17` for PostgreSQL or `8.4` for MySQL: AWS picks the newest minor version, and the minor upgrades AWS applies later (see `maintenance.auto_minor_version_upgrade`) do not show as changes. With a full version such as `17.6`, every plan after AWS upgrades the minor version tries to go back to it, and fails. Without a value, AWS uses the engine's default version.

A higher major version upgrades the database in place, and needs `maintenance.allow_major_version_upgrade = true`, and usually a parameter group for the new version.

Type: `string`

Default: `null`

#### <a name="input_iam_database_authentication_enabled"></a> [iam_database_authentication_enabled](#input_iam_database_authentication_enabled)

Description: Let database users sign in with an AWS Identity and Access Management (IAM) authentication token instead of a password. Supported by PostgreSQL, MySQL and MariaDB, and on by default for them; each database user must still be set up for it inside the database. Without a value, it is on for those engines and off for the others.

Type: `bool`

Default: `null`

#### <a name="input_kms_key_id"></a> [kms_key_id](#input_kms_key_id)

Description: ARN of the AWS Key Management Service (KMS) key that encrypts the database's storage, automated backups, snapshots, read replicas and Performance Insights data. The database is always encrypted; without a key, RDS uses the AWS managed key `aws/rds`, which cannot be shared with other accounts.

Changing the key later, including setting one, replaces the database instance and deletes its data: RDS cannot change the key of an existing instance.

Type: `string`

Default: `null`

#### <a name="input_license_model"></a> [license_model](#input_license_model)

Description: The license model, for engines that have more than one: `license-included` or `bring-your-own-license` (Oracle, Db2), `marketplace-license` (Db2 through AWS Marketplace). Without it, AWS uses the engine's default.

Type: `string`

Default: `null`

#### <a name="input_maintenance"></a> [maintenance](#input_maintenance)

Description: When and how the database is changed.

- `window` - (Optional) The weekly time range, in UTC, for maintenance and for changes not applied immediately, such as `sun:05:00-sun:06:00`; at least 30 minutes. Without it, AWS picks one.
- `auto_minor_version_upgrade` - (Optional) Let AWS apply minor engine versions during the maintenance window. Defaults to `true`.
- `allow_major_version_upgrade` - (Optional) Allow a change of `engine_version` to a higher major version. Defaults to `false`.
- `apply_immediately` - (Optional) Apply changes as soon as they are made instead of in the next maintenance window. Defaults to `false`. Changes such as a new `instance_class` restart the database. Until a deferred change is applied, every plan shows it again.

Type:

```hcl
object({
    window                      = optional(string)
    auto_minor_version_upgrade  = optional(bool, true)
    allow_major_version_upgrade = optional(bool, false)
    apply_immediately           = optional(bool, false)
  })
```

Default: `{}`

#### <a name="input_master_user"></a> [master_user](#input_master_user)

Description: The database's master user. RDS creates its password and keeps it in AWS Secrets Manager, where RDS rotates it every 7 days; the module never sees it, so it is not in the Terraform state. The secret's ARN is in the `metadata` output, at `db_instance.master_user_secret[0].secret_arn`.

With `read_replicas`, on any engine but SQL Server and Db2, AWS does not allow that. The module then creates a 30-character password itself and keeps it, with the user name, in a Secrets Manager secret of its own, at `metadata.secretsmanager_secret.arn`. That password is in the Terraform state, so protect the state, and it is not rotated. Adding the first replica to an existing database, or removing the last, switches between the two, and the password changes; see the README for two traps when removing the last replica.

- `username` - (Optional) The master user's name, such as `dbadmin`: a letter, then letters, digits and underscores. Required unless `snapshot_identifier` is set, when the snapshot's master user is kept. Each engine has its own length limit and reserved words, such as `rdsadmin`. Changing it later has no effect: the module ignores changes to it, because AWS can change it only by replacing the database.
- `secret_kms_key_id` - (Optional) The KMS key that encrypts the secret, either one: a key ID, key ARN, alias name or alias ARN. Without it, Secrets Manager uses the AWS managed key `aws/secretsmanager`.

Type:

```hcl
object({
    username          = optional(string)
    secret_kms_key_id = optional(string)
  })
```

Default: `{}`

#### <a name="input_monitoring_interval"></a> [monitoring_interval](#input_monitoring_interval)

Description: Seconds between Enhanced Monitoring samples of the operating system, sent to CloudWatch Logs in the `RDSOSMetrics` log group: `1`, `5`, `10`, `15`, `30` or `60`, or `0` for none. Defaults to `0`. Enhanced Monitoring is billed as CloudWatch Logs. With a value above `0`, the module creates the IAM role RDS uses to send the metrics, named `rds-monitoring-` followed by a unique suffix.

Type: `number`

Default: `0`

#### <a name="input_multi_az"></a> [multi_az](#input_multi_az)

Description: Keep a standby copy of the database in another Availability Zone, which RDS fails over to when the primary or its zone fails. It about doubles the instance and storage cost. Defaults to `false`. Turning it on later happens in place, without an outage.

Type: `bool`

Default: `false`

#### <a name="input_nchar_character_set_name"></a> [nchar_character_set_name](#input_nchar_character_set_name)

Description: The national character set, for Oracle only: `AL16UTF16` (the default) or `UTF8`. Changing it later replaces the database instance.

Type: `string`

Default: `null`

#### <a name="input_option_group_name"></a> [option_group_name](#input_option_group_name)

Description: The name of an option group to turn on engine features, such as Oracle Transparent Data Encryption or SQL Server native backups. Without it, AWS uses the engine version's default option group.

Type: `string`

Default: `null`

#### <a name="input_parameter_group_name"></a> [parameter_group_name](#input_parameter_group_name)

Description: The name of a DB parameter group for engine settings, such as `rds.force_ssl` or the MySQL slow query log. It must be for the engine's parameter group family, such as `postgres17`. Without it, AWS uses the family's default parameter group, which cannot be changed. Changing it later needs a restart before the new settings apply.

Type: `string`

Default: `null`

#### <a name="input_performance_insights"></a> [performance_insights](#input_performance_insights)

Description: Performance Insights, which records database load and the queries causing it. The first 7 days of history are free; longer retention is billed.

- `enabled` - (Optional) Turn it on. Defaults to `false`. Not every engine and instance class supports it: MySQL and MariaDB on `db.t3` and `db.t4g` micro and small classes do not, and AWS refuses to create such an instance with it on. `aws rds describe-orderable-db-instance-options` shows `SupportsPerformanceInsights` for each.
- `retention_period` - (Optional) Days of history to keep: `7`, `731`, or a multiple of `31` up to `713`. Defaults to `7`.

The data is encrypted with `kms_key_id`, or with `aws/rds` without it. Once Performance Insights has been on with one key, it cannot be turned on with another.

Type:

```hcl
object({
    enabled          = optional(bool, false)
    retention_period = optional(number, 7)
  })
```

Default: `{}`

#### <a name="input_port"></a> [port](#input_port)

Description: The port the database listens on, from `1150` to `65535`. Without it, the module uses the engine's default: `5432` for PostgreSQL, `3306` for MySQL and MariaDB, `1521` for Oracle, `1433` for SQL Server and `50000` for Db2. The security group allows this port. Changing it later restarts the database.

Type: `number`

Default: `null`

#### <a name="input_publicly_accessible"></a> [publicly_accessible](#input_publicly_accessible)

Description: Give the database a public IP address, so its endpoint resolves to it from outside the VPC. Defaults to `false`. It also needs public subnets in `db_subnet_group_name` and a `security_group_ingress` source outside the VPC. Keep databases private; reach them through the VPC instead.

Type: `bool`

Default: `false`

#### <a name="input_read_replicas"></a> [read_replicas](#input_read_replicas)

Description: Read replicas in the same Region: copies of the database that RDS keeps up to date asynchronously, for read-only queries. They are named `<identifier>-replica-1`, `-replica-2` and so on, and use the primary's subnet group, security groups, parameter and option groups, port, Performance Insights, Enhanced Monitoring and log settings.

- `count` - (Optional) How many, from `0` to `15`. Defaults to `0`. Lowering it deletes the replicas with the highest numbers.
- `instance_class` - (Optional) The replicas' instance class. Defaults to `instance_class`.
- `multi_az` - (Optional) Give each replica a standby in another Availability Zone. Defaults to `false`.

Replicas need automated backups on the primary (`backup.retention_period` above `0`). Oracle needs Enterprise Edition with an Active Data Guard license, and SQL Server needs Enterprise Edition. Except on SQL Server and Db2, AWS does not create replicas of a database whose password RDS manages, so with replicas the module manages the master password instead, and it is in the Terraform state (see `master_user`).

Type:

```hcl
object({
    count          = optional(number, 0)
    instance_class = optional(string)
    multi_az       = optional(bool, false)
  })
```

Default: `{}`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the database and everything else in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.

Type: `string`

Default: `null`

#### <a name="input_security_group_ingress"></a> [security_group_ingress](#input_security_group_ingress)

Description: Who can reach the database over the network. The module creates a security group for the database instance and its read replicas that allows the database port (TCP) from each source listed here, and from nothing else. It allows no outbound traffic: the database only answers connections, and security groups let replies out on their own. With the default, `{}`, no client can connect. The keys are names you choose; they only identify each rule, so a security group created in the same configuration can be used.

Each source takes exactly one of:

- `cidr_ipv4` - An IPv4 range, such as `10.0.0.0/16`.
- `cidr_ipv6` - An IPv6 range, such as `2600:1f18:1234:5600::/56`.
- `security_group_id` - A security group whose members may connect, such as the group of your application servers.
- `prefix_list_id` - A managed prefix list of ranges.

and optionally:

- `description` - (Optional) What the source is. Defaults to the key.

Type:

```hcl
map(object({
    cidr_ipv4         = optional(string)
    cidr_ipv6         = optional(string)
    security_group_id = optional(string)
    prefix_list_id    = optional(string)
    description       = optional(string)
  }))
```

Default: `{}`

#### <a name="input_snapshot_identifier"></a> [snapshot_identifier](#input_snapshot_identifier)

Description: Create the database from this DB snapshot: its identifier, or its ARN for a snapshot shared from another account. The snapshot's engine, master user, database name and storage size are used. Only read when the database is created; changing it later has no effect. A snapshot encrypted with another account's key, or with `aws/rds`, must first be copied with a key this account can use.

Type: `string`

Default: `null`

#### <a name="input_storage"></a> [storage](#input_storage)

Description: The database's storage.

- `type` - (Optional) `gp3`, the default (General Purpose SSD), `gp2`, `io1` or `io2` (Provisioned IOPS SSD), or `standard` (magnetic, previous generation).
- `allocated` - (Optional) Size in GiB. Defaults to `20`, the smallest most engines allow; when restoring from `snapshot_identifier`, defaults to the snapshot's size. Storage can grow later in place, but never shrink, and after a change AWS allows the next one only after 6 hours.
- `max_allocated` - (Optional) Turn on storage autoscaling: RDS grows the storage on its own, up to this many GiB, when it runs low. Must be more than `allocated`. Changes made this way do not show in plans.
- `iops` - (Optional) Provisioned I/O operations per second. Required for `io1` and `io2`. With `gp3`, AWS accepts it only above a size that depends on the engine (400 GiB for PostgreSQL, MySQL and MariaDB); below it, gp3 includes 3,000 IOPS.
- `throughput` - (Optional) Provisioned throughput in MiB/s, for `gp3` only, with the same size limit as `iops`.

Type:

```hcl
object({
    type          = optional(string, "gp3")
    allocated     = optional(number)
    max_allocated = optional(number)
    iops          = optional(number)
    throughput    = optional(number)
  })
```

Default: `{}`

#### <a name="input_timeouts"></a> [timeouts](#input_timeouts)

Description: How long Terraform waits for the database instance and each read replica.

- `create` - (Optional) Defaults to `180m`. Restores from large snapshots can take hours.
- `update` - (Optional) Defaults to `120m`.
- `delete` - (Optional) Defaults to `120m`.

Type:

```hcl
object({
    create = optional(string, "180m")
    update = optional(string, "120m")
    delete = optional(string, "120m")
  })
```

Default: `{}`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
- `db_instance` - The database instance: its `address` (the host name clients connect to), `port`, `endpoint` (`address:port`), `arn`, `identifier`, `resource_id` (for IAM authentication policies), `engine_version_actual`, `master_user_secret` (a list with the `secret_arn` and `kms_key_id` of the secret RDS manages, empty when the module manages the password), and the rest of its attributes. `status` and `latest_restorable_time` are left out because they change on their own.
- `db_instance_replica` - The read replicas, in order (`<identifier>-replica-1` first), each with the same attributes as `db_instance`, or `null` when there are none.
- `secretsmanager_secret` - The secret the module creates for the master password when there are read replicas on an engine other than SQL Server or Db2, with its `arn` and `name`, or `null` when RDS manages the password (see `master_user`).
- `security_group` - The database's security group, with its `id`, `arn` and `name`.
- `vpc_security_group_ingress_rule` - The ingress rules, keyed like `security_group_ingress`, or `null` when there are none.
- `cloudwatch_log_group` - The log groups, keyed `<instance identifier>/<log type>`, each with its `name`, `arn` and `retention_in_days`, or `null` when no logs are published.
- `iam_role` - The Enhanced Monitoring role, with its `arn` and `name`, or `null` when `monitoring_interval` is `0`.
- `iam_role_policy_attachment` - The attachment of the `AmazonRDSEnhancedMonitoringRole` policy to that role, or `null`.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-rds/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-rds/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
