resource "aws_iam_user" "developer" {
  name          = "${var.lab_prefix}-developer-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name   = "${var.lab_prefix}-developer"
    Role   = "Application Developer"
    Access = "Programmatic"
  })
}

resource "aws_iam_access_key" "developer" {
  user = aws_iam_user.developer.name
}

resource "aws_iam_user_policy" "developer_base" {
  name = "${var.lab_prefix}-developer-base-policy"
  user = aws_iam_user.developer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOnlyIAM"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:GetUserPolicy",
          "iam:ListUserPolicies",
          "iam:ListAttachedUserPolicies",
          "iam:ListRoles"
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMReadConfig"
        Effect = "Allow"
        Action = [
          "ssm:DescribeParameters",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3ListBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/developer/*"
      }
    ]
  })
}

resource "aws_iam_user_policy" "developer_self_manage" {
  name = "${var.lab_prefix}-developer-self-service-policy"
  user = aws_iam_user.developer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SelfManageCredentials"
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:UpdateAccessKey",
          "iam:ListAccessKeys",
          "iam:GetAccessKeyLastUsed"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
      },
      {
        Sid    = "SelfManagePolicies"
        Effect = "Allow"
        Action = [
          "iam:PutUserPolicy",
          "iam:DeleteUserPolicy"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:user/*"
      }
    ]
  })
}

resource "aws_iam_role" "admin_automation" {
  name = "${var.lab_prefix}-admin-automation-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
      }
    }]
  })

  tags = merge(local.common_tags, {
    Purpose = "Automated administrative tasks"
  })
}

resource "aws_iam_role_policy" "admin_automation_s3" {
  name = "${var.lab_prefix}-full-s3-access"
  role = aws_iam_role.admin_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:*"]
      Resource = "*"
    }]
  })
}
