# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The log groups RDS publishes to. They are created before the instances (see
# depends_on in db_instance.tf): if RDS wrote first, it would create them itself, with
# no retention, and this create would fail because they exist. A rename replaces them;
# the old ones are deleted only after the instance has its new name, or RDS would
# create them again (seen in AWS).
resource "aws_cloudwatch_log_group" "this" {
  for_each = local.cloudwatch_log_groups

  region            = var.region
  name              = each.value
  retention_in_days = var.cloudwatch_logs.retention_in_days
  kms_key_id        = var.cloudwatch_logs.kms_key_id

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}
