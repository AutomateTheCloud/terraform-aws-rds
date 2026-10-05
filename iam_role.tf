# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The role RDS assumes to send Enhanced Monitoring metrics to CloudWatch Logs. IAM
# names are global, so a prefix with a unique suffix lets the module be used for
# instances with the same identifier in several Regions.
resource "aws_iam_role" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name_prefix = "rds-monitoring-"
  description = "${local.scope.name} - ${local.purpose.name} [${local.environment.name}] (${local.aws.region.name}): RDS Enhanced Monitoring for ${var.identifier}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = data.aws_service_principal.monitoring[0].name }
      Action    = "sts:AssumeRole"
      # Only RDS acting for this account may assume the role.
      Condition = { StringEquals = { "aws:SourceAccount" = local.aws.account.id } }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:${data.aws_partition.this.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
