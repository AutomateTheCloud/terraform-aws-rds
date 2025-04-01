output "metadata" {
  description = "Metadata"
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

    cloudwatch = {
      log_group = {
        instance = try(aws_cloudwatch_log_group.this[*], null)
        replica  = try(aws_cloudwatch_log_group.replica[*], null)
      }
    }

    iam = {
      role = {
        rds_enhanced_monitoring = try(aws_iam_role.rds_enhanced_monitoring[0], null)
      }
    }
    rds = {
      instance = {
        address                               = try(aws_db_instance.this.address, null)
        allocated_storage                     = try(aws_db_instance.this.allocated_storage, null)
        allow_major_version_upgrade           = try(aws_db_instance.this.allow_major_version_upgrade, null)
        arn                                   = try(aws_db_instance.this.arn, null)
        auto_minor_version_upgrade            = try(aws_db_instance.this.auto_minor_version_upgrade, null)
        availability_zone                     = try(aws_db_instance.this.availability_zone, null)
        backup_retention_period               = try(aws_db_instance.this.backup_retention_period, null)
        backup_window                         = try(aws_db_instance.this.backup_window, null)
        ca_cert_identifier                    = try(aws_db_instance.this.ca_cert_identifier, null)
        character_set_name                    = try(aws_db_instance.this.character_set_name, null)
        db_name                               = try(aws_db_instance.this.db_name, null)
        db_subnet_group_name                  = try(aws_db_instance.this.db_subnet_group_name, null)
        domain                                = try(aws_db_instance.this.domain, null)
        domain_iam_role_name                  = try(aws_db_instance.this.domain_iam_role_name, null)
        enabled_cloudwatch_logs_exports       = try(aws_db_instance.this.enabled_cloudwatch_logs_exports, null)
        endpoint                              = try(aws_db_instance.this.endpoint, null)
        engine                                = try(aws_db_instance.this.engine, null)
        engine_version                        = try(aws_db_instance.this.engine_version, null)
        engine_version_actual                 = try(aws_db_instance.this.engine_version_actual, null)
        hosted_zone_id                        = try(aws_db_instance.this.hosted_zone_id, null)
        iam_database_authentication_enabled   = try(aws_db_instance.this.iam_database_authentication_enabled, null)
        id                                    = try(aws_db_instance.this.id, null)
        identifier                            = try(aws_db_instance.this.identifier, null)
        instance_class                        = try(aws_db_instance.this.instance_class, null)
        iops                                  = try(aws_db_instance.this.iops, null)
        kms_key_id                            = try(aws_db_instance.this.kms_key_id, null)
        license_model                         = try(aws_db_instance.this.license_model, null)
        maintenance_window                    = try(aws_db_instance.this.maintenance_window, null)
        max_allocated_storage                 = try(aws_db_instance.this.max_allocated_storage, null)
        monitoring_interval                   = try(aws_db_instance.this.monitoring_interval, null)
        monitoring_role_arn                   = try(aws_db_instance.this.monitoring_role_arn, null)
        multi_az                              = try(aws_db_instance.this.multi_az, null)
        nchar_character_set_name              = try(aws_db_instance.this.nchar_character_set_name, null)
        option_group_name                     = try(aws_db_instance.this.option_group_name, null)
        parameter_group_name                  = try(aws_db_instance.this.parameter_group_name, null)
        performance_insights_enabled          = try(aws_db_instance.this.performance_insights_enabled, null)
        performance_insights_kms_key_id       = try(aws_db_instance.this.performance_insights_kms_key_id, null)
        performance_insights_retention_period = try(aws_db_instance.this.performance_insights_retention_period, null)
        port                                  = try(aws_db_instance.this.port, null)
        publicly_accessible                   = try(aws_db_instance.this.publicly_accessible, null)
        replica_mode                          = try(aws_db_instance.this.replica_mode, null)
        replicate_source_db                   = try(aws_db_instance.this.replicate_source_db, null)
        resource_id                           = try(aws_db_instance.this.resource_id, null)
        storage_encrypted                     = try(aws_db_instance.this.storage_encrypted, null)
        storage_type                          = try(aws_db_instance.this.storage_type, null)
        tags                                  = try(aws_db_instance.this.tags, null)
        tags_all                              = try(aws_db_instance.this.tags_all, null)
        timezone                              = try(aws_db_instance.this.timezone, null)
        username                              = try(aws_db_instance.this.username, null)
        vpc_security_group_ids                = try(aws_db_instance.this.vpc_security_group_ids, null)
      }

      replica = [
        for i, r in aws_db_instance.replica : {
          address                               = try(r.address, null)
          allocated_storage                     = try(r.allocated_storage, null)
          allow_major_version_upgrade           = try(r.allow_major_version_upgrade, null)
          arn                                   = try(r.arn, null)
          auto_minor_version_upgrade            = try(r.auto_minor_version_upgrade, null)
          availability_zone                     = try(r.availability_zone, null)
          backup_retention_period               = try(r.backup_retention_period, null)
          backup_window                         = try(r.backup_window, null)
          ca_cert_identifier                    = try(r.ca_cert_identifier, null)
          character_set_name                    = try(r.character_set_name, null)
          db_name                               = try(r.db_name, null)
          db_subnet_group_name                  = try(r.db_subnet_group_name, null)
          domain                                = try(r.domain, null)
          domain_iam_role_name                  = try(r.domain_iam_role_name, null)
          enabled_cloudwatch_logs_exports       = try(r.enabled_cloudwatch_logs_exports, null)
          endpoint                              = try(r.endpoint, null)
          engine                                = try(r.engine, null)
          engine_version                        = try(r.engine_version, null)
          engine_version_actual                 = try(r.engine_version_actual, null)
          hosted_zone_id                        = try(r.hosted_zone_id, null)
          iam_database_authentication_enabled   = try(r.iam_database_authentication_enabled, null)
          id                                    = try(r.id, null)
          identifier                            = try(r.identifier, null)
          instance_class                        = try(r.instance_class, null)
          iops                                  = try(r.iops, null)
          kms_key_id                            = try(r.kms_key_id, null)
          license_model                         = try(r.license_model, null)
          maintenance_window                    = try(r.maintenance_window, null)
          max_allocated_storage                 = try(r.max_allocated_storage, null)
          monitoring_interval                   = try(r.monitoring_interval, null)
          monitoring_role_arn                   = try(r.monitoring_role_arn, null)
          multi_az                              = try(r.multi_az, null)
          name                                  = try(r.name, null)
          nchar_character_set_name              = try(r.nchar_character_set_name, null)
          option_group_name                     = try(r.option_group_name, null)
          parameter_group_name                  = try(r.parameter_group_name, null)
          performance_insights_enabled          = try(r.performance_insights_enabled, null)
          performance_insights_kms_key_id       = try(r.performance_insights_kms_key_id, null)
          performance_insights_retention_period = try(r.performance_insights_retention_period, null)
          port                                  = try(r.port, null)
          publicly_accessible                   = try(r.publicly_accessible, null)
          replica_mode                          = try(r.replica_mode, null)
          replicate_source_db                   = try(r.replicate_source_db, null)
          resource_id                           = try(r.resource_id, null)
          storage_encrypted                     = try(r.storage_encrypted, null)
          storage_type                          = try(r.storage_type, null)
          tags                                  = try(r.tags, null)
          tags_all                              = try(r.tags_all, null)
          timezone                              = try(r.timezone, null)
          username                              = try(r.username, null)
          vpc_security_group_ids                = try(r.vpc_security_group_ids, null)
        }
      ]
    }
    security_group = try(aws_security_group.this, null)
  }
}
