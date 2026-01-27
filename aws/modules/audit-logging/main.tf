resource "aws_s3_bucket" "logs" {
  bucket        = "${var.name_prefix}-cloudtrail-${var.suffix}"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name                          = "${var.name_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.logs.id
  include_global_service_events = var.include_global_events
  is_multi_region_trail         = var.multi_region
  enable_logging                = true

  dynamic "event_selector" {
    for_each = length(var.data_resources) > 0 ? [1] : []
    content {
      read_write_type           = var.read_write_type
      include_management_events = var.include_management_events

      dynamic "data_resource" {
        for_each = var.data_resources
        content {
          type   = data_resource.value.type
          values = data_resource.value.values
        }
      }
    }
  }

  tags = var.tags

  depends_on = [aws_s3_bucket_policy.logs]
}