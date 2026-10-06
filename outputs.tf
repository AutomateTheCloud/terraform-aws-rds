# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

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
  EOT
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    # One entry per resource. Resources that are not created are null.
    cloudwatch_log_group            = local.output_resources.cloudwatch_log_group
    db_instance                     = local.output_resources.db_instance
    db_instance_replica             = local.output_resources.db_instance_replica
    iam_role                        = local.output_resources.iam_role
    iam_role_policy_attachment      = local.output_resources.iam_role_policy_attachment
    secretsmanager_secret           = local.output_resources.secretsmanager_secret
    security_group                  = local.output_resources.security_group
    vpc_security_group_ingress_rule = local.output_resources.vpc_security_group_ingress_rule
  }
}

locals {
  # Each resource's attributes are listed one by one. Referencing a whole resource, or
  # iterating over it, would also reference its deprecated and sensitive attributes, and
  # every caller's plan would print deprecation warnings or the output would become
  # sensitive. Keyed and counted resources are indexed from the inputs for the same
  # reason. Attributes that change on their own after an apply (status,
  # latest_restorable_time, and the primary's list of replicas, filled in after the
  # replicas are created) are left out, or every plan would show the output changing.
  # So are domain_dns_ips and enabled_cloudwatch_logs_exports: when empty, the provider
  # saves them as null and reads them back as [], so the first plan after a create
  # showed the output changing (seen in AWS). The log types are in var.cloudwatch_logs.
  output_resources = {
    db_instance = {
      address                               = aws_db_instance.this.address
      allocated_storage                     = aws_db_instance.this.allocated_storage
      allow_major_version_upgrade           = aws_db_instance.this.allow_major_version_upgrade
      apply_immediately                     = aws_db_instance.this.apply_immediately
      arn                                   = aws_db_instance.this.arn
      auto_minor_version_upgrade            = aws_db_instance.this.auto_minor_version_upgrade
      availability_zone                     = aws_db_instance.this.availability_zone
      backup_retention_period               = aws_db_instance.this.backup_retention_period
      backup_target                         = aws_db_instance.this.backup_target
      backup_window                         = aws_db_instance.this.backup_window
      blue_green_update                     = aws_db_instance.this.blue_green_update
      ca_cert_identifier                    = aws_db_instance.this.ca_cert_identifier
      character_set_name                    = aws_db_instance.this.character_set_name
      copy_tags_to_snapshot                 = aws_db_instance.this.copy_tags_to_snapshot
      custom_iam_instance_profile           = aws_db_instance.this.custom_iam_instance_profile
      customer_owned_ip_enabled             = aws_db_instance.this.customer_owned_ip_enabled
      database_insights_mode                = aws_db_instance.this.database_insights_mode
      db_name                               = aws_db_instance.this.db_name
      db_subnet_group_name                  = aws_db_instance.this.db_subnet_group_name
      dedicated_log_volume                  = aws_db_instance.this.dedicated_log_volume
      delete_automated_backups              = aws_db_instance.this.delete_automated_backups
      deletion_protection                   = aws_db_instance.this.deletion_protection
      domain                                = aws_db_instance.this.domain
      domain_auth_secret_arn                = aws_db_instance.this.domain_auth_secret_arn
      domain_fqdn                           = aws_db_instance.this.domain_fqdn
      domain_iam_role_name                  = aws_db_instance.this.domain_iam_role_name
      domain_ou                             = aws_db_instance.this.domain_ou
      endpoint                              = aws_db_instance.this.endpoint
      engine                                = aws_db_instance.this.engine
      engine_lifecycle_support              = aws_db_instance.this.engine_lifecycle_support
      engine_version                        = aws_db_instance.this.engine_version
      engine_version_actual                 = aws_db_instance.this.engine_version_actual
      final_snapshot_identifier             = aws_db_instance.this.final_snapshot_identifier
      hosted_zone_id                        = aws_db_instance.this.hosted_zone_id
      iam_database_authentication_enabled   = aws_db_instance.this.iam_database_authentication_enabled
      id                                    = aws_db_instance.this.id
      identifier                            = aws_db_instance.this.identifier
      identifier_prefix                     = aws_db_instance.this.identifier_prefix
      instance_class                        = aws_db_instance.this.instance_class
      iops                                  = aws_db_instance.this.iops
      kms_key_id                            = aws_db_instance.this.kms_key_id
      license_model                         = aws_db_instance.this.license_model
      listener_endpoint                     = aws_db_instance.this.listener_endpoint
      maintenance_window                    = aws_db_instance.this.maintenance_window
      manage_master_user_password           = aws_db_instance.this.manage_master_user_password
      master_user_secret                    = aws_db_instance.this.master_user_secret
      master_user_secret_kms_key_id         = aws_db_instance.this.master_user_secret_kms_key_id
      max_allocated_storage                 = aws_db_instance.this.max_allocated_storage
      monitoring_interval                   = aws_db_instance.this.monitoring_interval
      monitoring_role_arn                   = aws_db_instance.this.monitoring_role_arn
      multi_az                              = aws_db_instance.this.multi_az
      nchar_character_set_name              = aws_db_instance.this.nchar_character_set_name
      network_type                          = aws_db_instance.this.network_type
      option_group_name                     = aws_db_instance.this.option_group_name
      parameter_group_name                  = aws_db_instance.this.parameter_group_name
      password_wo_version                   = aws_db_instance.this.password_wo_version
      performance_insights_enabled          = aws_db_instance.this.performance_insights_enabled
      performance_insights_kms_key_id       = aws_db_instance.this.performance_insights_kms_key_id
      performance_insights_retention_period = aws_db_instance.this.performance_insights_retention_period
      port                                  = aws_db_instance.this.port
      publicly_accessible                   = aws_db_instance.this.publicly_accessible
      region                                = aws_db_instance.this.region
      replica_mode                          = aws_db_instance.this.replica_mode
      replicate_source_db                   = aws_db_instance.this.replicate_source_db
      resource_id                           = aws_db_instance.this.resource_id
      restore_to_point_in_time              = aws_db_instance.this.restore_to_point_in_time
      s3_import                             = aws_db_instance.this.s3_import
      skip_final_snapshot                   = aws_db_instance.this.skip_final_snapshot
      snapshot_identifier                   = aws_db_instance.this.snapshot_identifier
      storage_encrypted                     = aws_db_instance.this.storage_encrypted
      storage_throughput                    = aws_db_instance.this.storage_throughput
      storage_type                          = aws_db_instance.this.storage_type
      tags                                  = aws_db_instance.this.tags
      tags_all                              = aws_db_instance.this.tags_all
      timezone                              = aws_db_instance.this.timezone
      upgrade_storage_config                = aws_db_instance.this.upgrade_storage_config
      username                              = aws_db_instance.this.username
      vpc_security_group_ids                = aws_db_instance.this.vpc_security_group_ids
    }
    db_instance_replica = var.read_replicas.count == 0 ? null : [
      for i in range(var.read_replicas.count) : {
        address                               = aws_db_instance.replica[i].address
        allocated_storage                     = aws_db_instance.replica[i].allocated_storage
        allow_major_version_upgrade           = aws_db_instance.replica[i].allow_major_version_upgrade
        apply_immediately                     = aws_db_instance.replica[i].apply_immediately
        arn                                   = aws_db_instance.replica[i].arn
        auto_minor_version_upgrade            = aws_db_instance.replica[i].auto_minor_version_upgrade
        availability_zone                     = aws_db_instance.replica[i].availability_zone
        backup_retention_period               = aws_db_instance.replica[i].backup_retention_period
        backup_target                         = aws_db_instance.replica[i].backup_target
        backup_window                         = aws_db_instance.replica[i].backup_window
        blue_green_update                     = aws_db_instance.replica[i].blue_green_update
        ca_cert_identifier                    = aws_db_instance.replica[i].ca_cert_identifier
        character_set_name                    = aws_db_instance.replica[i].character_set_name
        copy_tags_to_snapshot                 = aws_db_instance.replica[i].copy_tags_to_snapshot
        custom_iam_instance_profile           = aws_db_instance.replica[i].custom_iam_instance_profile
        customer_owned_ip_enabled             = aws_db_instance.replica[i].customer_owned_ip_enabled
        database_insights_mode                = aws_db_instance.replica[i].database_insights_mode
        db_name                               = aws_db_instance.replica[i].db_name
        db_subnet_group_name                  = aws_db_instance.replica[i].db_subnet_group_name
        dedicated_log_volume                  = aws_db_instance.replica[i].dedicated_log_volume
        delete_automated_backups              = aws_db_instance.replica[i].delete_automated_backups
        deletion_protection                   = aws_db_instance.replica[i].deletion_protection
        domain                                = aws_db_instance.replica[i].domain
        domain_auth_secret_arn                = aws_db_instance.replica[i].domain_auth_secret_arn
        domain_fqdn                           = aws_db_instance.replica[i].domain_fqdn
        domain_iam_role_name                  = aws_db_instance.replica[i].domain_iam_role_name
        domain_ou                             = aws_db_instance.replica[i].domain_ou
        endpoint                              = aws_db_instance.replica[i].endpoint
        engine                                = aws_db_instance.replica[i].engine
        engine_lifecycle_support              = aws_db_instance.replica[i].engine_lifecycle_support
        engine_version                        = aws_db_instance.replica[i].engine_version
        engine_version_actual                 = aws_db_instance.replica[i].engine_version_actual
        final_snapshot_identifier             = aws_db_instance.replica[i].final_snapshot_identifier
        hosted_zone_id                        = aws_db_instance.replica[i].hosted_zone_id
        iam_database_authentication_enabled   = aws_db_instance.replica[i].iam_database_authentication_enabled
        id                                    = aws_db_instance.replica[i].id
        identifier                            = aws_db_instance.replica[i].identifier
        identifier_prefix                     = aws_db_instance.replica[i].identifier_prefix
        instance_class                        = aws_db_instance.replica[i].instance_class
        iops                                  = aws_db_instance.replica[i].iops
        kms_key_id                            = aws_db_instance.replica[i].kms_key_id
        license_model                         = aws_db_instance.replica[i].license_model
        listener_endpoint                     = aws_db_instance.replica[i].listener_endpoint
        maintenance_window                    = aws_db_instance.replica[i].maintenance_window
        manage_master_user_password           = aws_db_instance.replica[i].manage_master_user_password
        master_user_secret                    = aws_db_instance.replica[i].master_user_secret
        master_user_secret_kms_key_id         = aws_db_instance.replica[i].master_user_secret_kms_key_id
        max_allocated_storage                 = aws_db_instance.replica[i].max_allocated_storage
        monitoring_interval                   = aws_db_instance.replica[i].monitoring_interval
        monitoring_role_arn                   = aws_db_instance.replica[i].monitoring_role_arn
        multi_az                              = aws_db_instance.replica[i].multi_az
        nchar_character_set_name              = aws_db_instance.replica[i].nchar_character_set_name
        network_type                          = aws_db_instance.replica[i].network_type
        option_group_name                     = aws_db_instance.replica[i].option_group_name
        parameter_group_name                  = aws_db_instance.replica[i].parameter_group_name
        password_wo_version                   = aws_db_instance.replica[i].password_wo_version
        performance_insights_enabled          = aws_db_instance.replica[i].performance_insights_enabled
        performance_insights_kms_key_id       = aws_db_instance.replica[i].performance_insights_kms_key_id
        performance_insights_retention_period = aws_db_instance.replica[i].performance_insights_retention_period
        port                                  = aws_db_instance.replica[i].port
        publicly_accessible                   = aws_db_instance.replica[i].publicly_accessible
        region                                = aws_db_instance.replica[i].region
        replica_mode                          = aws_db_instance.replica[i].replica_mode
        replicate_source_db                   = aws_db_instance.replica[i].replicate_source_db
        resource_id                           = aws_db_instance.replica[i].resource_id
        restore_to_point_in_time              = aws_db_instance.replica[i].restore_to_point_in_time
        s3_import                             = aws_db_instance.replica[i].s3_import
        skip_final_snapshot                   = aws_db_instance.replica[i].skip_final_snapshot
        snapshot_identifier                   = aws_db_instance.replica[i].snapshot_identifier
        storage_encrypted                     = aws_db_instance.replica[i].storage_encrypted
        storage_throughput                    = aws_db_instance.replica[i].storage_throughput
        storage_type                          = aws_db_instance.replica[i].storage_type
        tags                                  = aws_db_instance.replica[i].tags
        tags_all                              = aws_db_instance.replica[i].tags_all
        timezone                              = aws_db_instance.replica[i].timezone
        upgrade_storage_config                = aws_db_instance.replica[i].upgrade_storage_config
        username                              = aws_db_instance.replica[i].username
        vpc_security_group_ids                = aws_db_instance.replica[i].vpc_security_group_ids
      }
    ]
    security_group = {
      arn                    = aws_security_group.this.arn
      description            = aws_security_group.this.description
      id                     = aws_security_group.this.id
      name                   = aws_security_group.this.name
      name_prefix            = aws_security_group.this.name_prefix
      owner_id               = aws_security_group.this.owner_id
      region                 = aws_security_group.this.region
      revoke_rules_on_delete = aws_security_group.this.revoke_rules_on_delete
      tags                   = aws_security_group.this.tags
      tags_all               = aws_security_group.this.tags_all
      vpc_id                 = aws_security_group.this.vpc_id
    }
    vpc_security_group_ingress_rule = length(var.security_group_ingress) == 0 ? null : {
      for k in keys(var.security_group_ingress) : k => {
        arn                          = aws_vpc_security_group_ingress_rule.this[k].arn
        cidr_ipv4                    = aws_vpc_security_group_ingress_rule.this[k].cidr_ipv4
        cidr_ipv6                    = aws_vpc_security_group_ingress_rule.this[k].cidr_ipv6
        description                  = aws_vpc_security_group_ingress_rule.this[k].description
        from_port                    = aws_vpc_security_group_ingress_rule.this[k].from_port
        id                           = aws_vpc_security_group_ingress_rule.this[k].id
        ip_protocol                  = aws_vpc_security_group_ingress_rule.this[k].ip_protocol
        prefix_list_id               = aws_vpc_security_group_ingress_rule.this[k].prefix_list_id
        referenced_security_group_id = aws_vpc_security_group_ingress_rule.this[k].referenced_security_group_id
        region                       = aws_vpc_security_group_ingress_rule.this[k].region
        security_group_id            = aws_vpc_security_group_ingress_rule.this[k].security_group_id
        security_group_rule_id       = aws_vpc_security_group_ingress_rule.this[k].security_group_rule_id
        tags                         = aws_vpc_security_group_ingress_rule.this[k].tags
        tags_all                     = aws_vpc_security_group_ingress_rule.this[k].tags_all
        to_port                      = aws_vpc_security_group_ingress_rule.this[k].to_port
      }
    }
    cloudwatch_log_group = length(local.cloudwatch_log_groups) == 0 ? null : {
      for k in keys(local.cloudwatch_log_groups) : k => {
        arn               = aws_cloudwatch_log_group.this[k].arn
        id                = aws_cloudwatch_log_group.this[k].id
        kms_key_id        = aws_cloudwatch_log_group.this[k].kms_key_id
        log_group_class   = aws_cloudwatch_log_group.this[k].log_group_class
        name              = aws_cloudwatch_log_group.this[k].name
        name_prefix       = aws_cloudwatch_log_group.this[k].name_prefix
        region            = aws_cloudwatch_log_group.this[k].region
        retention_in_days = aws_cloudwatch_log_group.this[k].retention_in_days
        skip_destroy      = aws_cloudwatch_log_group.this[k].skip_destroy
        tags              = aws_cloudwatch_log_group.this[k].tags
        tags_all          = aws_cloudwatch_log_group.this[k].tags_all
      }
    }
    secretsmanager_secret = local.manage_master_user_password ? null : {
      arn                            = aws_secretsmanager_secret.master[0].arn
      description                    = aws_secretsmanager_secret.master[0].description
      force_overwrite_replica_secret = aws_secretsmanager_secret.master[0].force_overwrite_replica_secret
      id                             = aws_secretsmanager_secret.master[0].id
      kms_key_id                     = aws_secretsmanager_secret.master[0].kms_key_id
      name                           = aws_secretsmanager_secret.master[0].name
      name_prefix                    = aws_secretsmanager_secret.master[0].name_prefix
      policy                         = aws_secretsmanager_secret.master[0].policy
      recovery_window_in_days        = aws_secretsmanager_secret.master[0].recovery_window_in_days
      region                         = aws_secretsmanager_secret.master[0].region
      replica                        = aws_secretsmanager_secret.master[0].replica
      tags                           = aws_secretsmanager_secret.master[0].tags
      tags_all                       = aws_secretsmanager_secret.master[0].tags_all
    }
    iam_role = var.monitoring_interval == 0 ? null : {
      arn                   = aws_iam_role.monitoring[0].arn
      assume_role_policy    = aws_iam_role.monitoring[0].assume_role_policy
      create_date           = aws_iam_role.monitoring[0].create_date
      description           = aws_iam_role.monitoring[0].description
      force_detach_policies = aws_iam_role.monitoring[0].force_detach_policies
      id                    = aws_iam_role.monitoring[0].id
      max_session_duration  = aws_iam_role.monitoring[0].max_session_duration
      name                  = aws_iam_role.monitoring[0].name
      name_prefix           = aws_iam_role.monitoring[0].name_prefix
      path                  = aws_iam_role.monitoring[0].path
      permissions_boundary  = aws_iam_role.monitoring[0].permissions_boundary
      tags                  = aws_iam_role.monitoring[0].tags
      tags_all              = aws_iam_role.monitoring[0].tags_all
      unique_id             = aws_iam_role.monitoring[0].unique_id
    }
    iam_role_policy_attachment = var.monitoring_interval == 0 ? null : {
      id         = aws_iam_role_policy_attachment.monitoring[0].id
      policy_arn = aws_iam_role_policy_attachment.monitoring[0].policy_arn
      role       = aws_iam_role_policy_attachment.monitoring[0].role
    }
  }
}
