# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The security group of the database instance and its read replicas. It allows the
# database port from the sources in security_group_ingress and nothing else. It has no
# egress rules: the database only answers connections, and security groups let replies
# out on their own. The AWS provider removes the rule that allows all outbound traffic,
# which AWS adds to every new group.
resource "aws_security_group" "this" {
  region                 = var.region
  name_prefix            = "${local.name}-"
  description            = local.security_group_description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(local.tags, { Name = local.name })

  # A new name or description replaces the group. Creating the new group first lets
  # the database move to it before the old one, which it still uses, is deleted.
  lifecycle {
    create_before_destroy = true
  }
}
