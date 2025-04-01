resource "aws_iam_role" "rds_enhanced_monitoring" {
  count              = var.monitoring_interval > 0 ? 1 : 0
  name               = "rds_em-${var.identifier}"
  description        = "${local.scope.name} - ${local.purpose.name} [${local.environment.name}] (${local.aws.region.name}): RDS Enhanced Monitoring - ${var.identifier}"
  assume_role_policy = data.aws_iam_policy_document.iam_role-rds_enhanced_monitoring[0].json
  tags               = local.tags
  provider           = aws.this
}

data "aws_iam_policy_document" "iam_role-rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
  provider = aws.this
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring[0].id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  provider   = aws.this
}
