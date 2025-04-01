data "aws_kms_key" "rds" {
  count    = try(local.kms_key_id, null) != null ? 1 : 0
  key_id   = local.kms_key_id
  provider = aws.this
}

data "aws_vpc" "this" {
  id       = var.vpc_id
  provider = aws.this
}
