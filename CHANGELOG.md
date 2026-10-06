# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Fixed

- The final snapshot's name now changes whenever the instance is replaced, not only when it is renamed. A replacement, such as a new `db_name`, kept the name, so the replaced instance's final snapshot took it, and deleting the new instance would then fail because a snapshot with that name exists. Upgrading from 1.0.0 gives an existing instance a new final snapshot name once, as an in-place change.

### Changed

- The copyright year in `NOTICE` and the file headers is now 2026, the year the module was rebuilt and released as 1.0.0.
- `CLAUDE.md`, the working rules shared by every Automate the Cloud module, adds the lessons learned while rebuilding the modules.

## [1.0.0] - 2026-10-05

Initial release.

### Added

- An RDS database instance for PostgreSQL, MySQL, MariaDB, Oracle, SQL Server or Db2, with secure defaults: always encrypted, private, protected from deletion, backed up for 7 days, and no network access until you allow a source.
- The master password created by RDS and kept, and rotated, in AWS Secrets Manager, so it does not appear in the Terraform state. With read replicas, which AWS does not allow with such a password except on SQL Server and Db2, the module creates the password and keeps it in a secret of its own.
- A security group that allows the database port from IPv4 and IPv6 ranges, security groups and prefix lists, and nothing else.
- IAM database authentication, on by default for PostgreSQL, MySQL and MariaDB.
- Read replicas in the same Region, a Multi-AZ standby, storage autoscaling, and gp3, io1 and io2 storage with provisioned IOPS and throughput.
- Logs published to CloudWatch Logs in log groups the module creates with your retention, Enhanced Monitoring with its IAM role, and Performance Insights.
- Restores from a DB snapshot, and a control over RDS Extended Support.
- `region`, to create the database in a Region other than the provider's.
- A `metadata` output with everything the module created.
- Offline tests, and examples for a basic database and most options together.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-rds/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/AutomateTheCloud/terraform-aws-rds/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-rds/releases/tag/v1.0.0
