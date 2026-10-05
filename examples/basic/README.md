# Basic database

A private, encrypted PostgreSQL 17 database in the subnets you give. Anything in the VPC can reach it on the PostgreSQL port. RDS creates the master password and keeps it in AWS Secrets Manager.

Everything else uses the module's defaults: the AWS managed key `aws/rds`, 20 GiB of gp3 storage, automated backups kept 7 days, deletion protection, and a final snapshot when the database is deleted.

## Run it

Choose a VPC and private subnets in at least two Availability Zones:

```shell
terraform init
terraform apply -var 'vpc_id=vpc-0123456789abcdef0' -var 'subnet_ids=["subnet-0123456789abcdef0","subnet-0fedcba9876543210"]'
```

Creating the database takes about 5 to 10 minutes. The `database` output gives its address and port, and the ARN of the secret that holds the master password. From an instance in the VPC:

```shell
PGPASSWORD=$(aws secretsmanager get-secret-value --secret-id '<secret ARN>' --query SecretString --output text | jq -r .password) \
  psql "host=<address> port=5432 user=dbadmin dbname=postgres sslmode=require"
```

To remove it, turn deletion protection off first: add `deletion = { protection = false }` to the module block and apply, then run `terraform destroy` with the same `-var` options. RDS takes a final snapshot, `example-basic-final-<8 hex digits>`, which is kept, and billed, until you delete it.

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

#### <a name="output_database"></a> [database](#output_database)

Description: Where to connect, and the ARN of the Secrets Manager secret that holds the master password
<!-- END_TF_DOCS -->
