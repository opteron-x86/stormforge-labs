resource "aws_iam_role" "webapp_instance" {
  name = "${var.lab_prefix}-webapp-role-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "webapp_logging" {
  name = "${var.lab_prefix}-logging-policy"
  role = aws_iam_role.webapp_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:*:*"
      },
      {
        Sid    = "S3LogAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:s3:::${var.lab_prefix}-*/*"
      },
      {
        Sid      = "S3ListBuckets"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:${data.aws_partition.current.partition}:s3:::${var.lab_prefix}-*"
      },
      {
        Sid    = "SSMConfigAccess"
        Effect = "Allow"
        Action = [
          "ssm:DescribeParameters",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "*"
      },
      {
        Sid      = "AssumeRoleAccess"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:${data.aws_partition.current.partition}:iam::*:role/${var.lab_prefix}-*"
      }
    ]
  })
}

resource "aws_iam_role" "data_processor" {
  name = "${var.lab_prefix}-data-processor-${random_string.suffix.result}"

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

  tags = local.common_tags
}

resource "aws_iam_role_policy" "data_processor_s3" {
  name = "${var.lab_prefix}-data-access"
  role = aws_iam_role.data_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.sensitive_data.arn,
        "${aws_s3_bucket.sensitive_data.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "webapp" {
  name = "${var.lab_prefix}-webapp-profile-${random_string.suffix.result}"
  role = aws_iam_role.webapp_instance.name
}