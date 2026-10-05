# Complete

Most of the module's options together, for an application's production database:

- PostgreSQL 17, with AWS upgrading it to a supported major version at the end of standard support instead of billing for RDS Extended Support.
- A customer managed AWS Key Management Service (KMS) key encrypts the storage, snapshots, read replica, Performance Insights data and the master password's secret.
- A standby in a second Availability Zone (Multi-AZ), and one read replica. Because AWS does not create replicas of a database whose password RDS manages, the module creates the master password and keeps it in a Secrets Manager secret of its own, so the password is also in the Terraform state; keep the state in an encrypted backend with restricted access.
- Storage starts at 20 GiB and grows on its own up to 100 GiB.
- Automated backups kept 14 days, taken at 03:00 UTC; maintenance on Sundays at 05:00 UTC.
- A parameter group that requires TLS and logs statements slower than one second, with the PostgreSQL and upgrade logs published to CloudWatch Logs for 30 days.
- Enhanced Monitoring every 60 seconds, and Performance Insights with the 7 days of history that are free.
- Only members of the application's security group can reach the database.

The example creates the KMS key, the subnet group, the parameter group and the application's security group. It does not create the application's servers: attach the `app_security_group_id` output's group to them.

## Run it

Choose a VPC and private subnets in at least two Availability Zones:

```shell
terraform init
terraform apply -var 'vpc_id=vpc-0123456789abcdef0' -var 'subnet_ids=["subnet-0123456789abcdef0","subnet-0fedcba9876543210"]'
```

Creating the database, its standby and the replica takes about 20 to 30 minutes.

To remove it, turn deletion protection off first: add `deletion = { protection = false }` to the module block and apply, then run `terraform destroy` with the same `-var` options. RDS takes a final snapshot of the primary, `example-complete-final-<8 hex digits>`, encrypted with the example's key; it is kept, and billed, until you delete it. KMS deletes the key seven days after the destroy, after which that snapshot can no longer be restored, so delete the snapshot, or keep the key, first.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

- <a name="requirement_random"></a> [random](#requirement_random) (~> 3.0)

### Required Inputs

The following input variables are required:

#### <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)

Description: IDs of private subnets for the database, in at least two Availability Zones

Type: `list(string)`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: ID of the VPC to create the database in

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_app_security_group_id"></a> [app_security_group_id](#output_app_security_group_id)

Description: The security group to attach to the application servers

#### <a name="output_database"></a> [database](#output_database)

Description: Where to connect, the replica's address, and the ARN of the Secrets Manager secret that holds the master password
<!-- END_TF_DOCS -->
