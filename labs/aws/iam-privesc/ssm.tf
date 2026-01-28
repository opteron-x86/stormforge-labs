resource "aws_ssm_parameter" "protected_bucket_name" {
  name  = "/${var.lab_prefix}/config/protected_bucket"
  type  = "String"
  value = aws_s3_bucket.protected_data.id

  tags = merge(local.common_tags, {
    Purpose = "S3 bucket name for protected data storage"
  })
}

resource "aws_ssm_parameter" "admin_role_arn" {
  name  = "/${var.lab_prefix}/config/admin_automation_role"
  type  = "String"
  value = aws_iam_role.admin_automation.arn

  tags = merge(local.common_tags, {
    Purpose = "Role ARN for administrative automation scripts"
  })
}

resource "aws_ssm_parameter" "security_note" {
  name  = "/${var.lab_prefix}/notes/security-review"
  type  = "String"
  value = "TODO: Review IAM policies for developers. Self-service policy may be too broad."

  tags = merge(local.common_tags, {
    Purpose = "Security team notes"
  })
}