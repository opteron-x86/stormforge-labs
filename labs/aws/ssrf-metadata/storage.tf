resource "aws_s3_bucket" "sensitive_data" {
  bucket        = "${var.lab_prefix}-customer-data-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name               = "${var.lab_prefix}-customer-data"
    DataClassification = "Internal"
  })
}

resource "aws_s3_bucket_versioning" "sensitive_data" {
  bucket = aws_s3_bucket.sensitive_data.id
  
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "sensitive_data" {
  bucket = aws_s3_bucket.sensitive_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "customer_data" {
  bucket  = aws_s3_bucket.sensitive_data.id
  key     = "customers/customer_database.csv"
  content = <<-EOT
customer_id,name,email,credit_card_last4,account_balance
1001,John Smith,jsmith@psychocorp.com,4532,15430.50
1002,Sarah Johnson,sjohnson@psychocorp.com,8921,8750.00
1003,Michael Brown,mbrown@psychocorp.com,3467,22100.75
1004,Emma Wilson,ewilson@psychocorp.com,9823,5600.25
EOT
}

resource "aws_s3_object" "api_keys" {
  bucket  = aws_s3_bucket.sensitive_data.id
  key     = "config/api_keys.json"
  content = jsonencode({
    production = {
      stripe_key   = "sk_live_simulated_key_do_not_use"
      db_password  = "SuperSecretPassword123!"
      api_endpoint = "https://internal-api.psychocorp.com"
    }
  })
}

resource "aws_ssm_parameter" "data_role_hint" {
  name  = "/${var.lab_prefix}/config/data_processor_role"
  type  = "String"
  value = aws_iam_role.data_processor.arn
  
  tags = merge(local.common_tags, {
    Purpose = "Batch processing role for ETL jobs"
  })
}