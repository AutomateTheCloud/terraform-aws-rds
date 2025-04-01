resource "aws_cloudwatch_log_group" "this" {
  count             = try(length(var.cloudwatch.exports), 0)
  name              = "/aws/rds/instance/${var.identifier}/${var.cloudwatch.exports[count.index]}"
  retention_in_days = try(var.cloudwatch.retention, 7)
  tags              = local.tags
  provider          = aws.this
}

resource "aws_cloudwatch_log_group" "replica" {
  count             = try(length(local.replica_cloudwatch_groups), 0)
  name              = "/aws/rds/instance/${local.replica_cloudwatch_groups[count.index].identifier}/${local.replica_cloudwatch_groups[count.index].cloudwatch_group}"
  retention_in_days = try(var.cloudwatch.retention, 7)
  tags              = local.tags
  provider          = aws.this
}
