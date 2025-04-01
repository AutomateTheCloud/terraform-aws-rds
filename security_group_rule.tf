resource "aws_security_group_rule" "ingress" {
  for_each                 = { for rule in var.security_group_rules : join(";", [rule.source]) => rule }
  security_group_id        = aws_security_group.this.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = local.port
  to_port                  = local.port
  cidr_blocks              = (can(cidrnetmask(each.value["source"])) ? [each.value["source"]] : null)
  source_security_group_id = (can(cidrnetmask(each.value["source"])) ? null : each.value["source"])
  description              = try(each.value["description"], null)
  provider                 = aws.this
}

resource "aws_security_group_rule" "ingress-self" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  self              = true
  description       = "Self Reference"
  provider          = aws.this
}

resource "aws_security_group_rule" "egress" {
  for_each                 = { for rule in var.security_group_rules : join(";", [rule.source]) => rule }
  security_group_id        = aws_security_group.this.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = local.port
  to_port                  = local.port
  cidr_blocks              = (can(cidrnetmask(each.value["source"])) ? [each.value["source"]] : null)
  source_security_group_id = (can(cidrnetmask(each.value["source"])) ? null : each.value["source"])
  description              = try(each.value["description"], null)
  provider                 = aws.this
}

resource "aws_security_group_rule" "egress-self" {
  security_group_id = aws_security_group.this.id
  type              = "egress"
  protocol          = -1
  from_port         = 0
  to_port           = 0
  self              = true
  description       = "Self Reference"
  provider          = aws.this
}
