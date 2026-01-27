resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  common_tags = {
    Environment  = "lab"
    Destroyable  = "true"
    Scenario     = "iam-privilege-escalation"
    AutoShutdown = "24hours"
  }
}

resource "aws_s3_bucket" "protected_data" {
  bucket        = "${var.lab_prefix}-protected-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name               = "${var.lab_prefix}-protected-data"
    DataClassification = "Confidential"
    Owner              = "Security Team"
  })
}

resource "aws_s3_bucket_versioning" "protected_data" {
  bucket = aws_s3_bucket.protected_data.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "protected_data" {
  bucket = aws_s3_bucket.protected_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "financial_records" {
  bucket  = aws_s3_bucket.protected_data.id
  key     = "financial/q4-2024-revenue.csv"
  content = <<-EOT
department,revenue,expenses,profit_margin
Engineering,2500000,1800000,28.0
Sales,3200000,900000,71.9
Marketing,800000,750000,6.3
Operations,1500000,1200000,20.0
FLAG{iam_wildcard_privilege_escalation_successful},999999999,0,100.0
EOT
}

resource "aws_s3_object" "credentials" {
  bucket  = aws_s3_bucket.protected_data.id
  key     = "secrets/production-credentials.json"
  content = jsonencode({
    database = {
      host     = "prod-db.internal.example.com"
      username = "admin"
      password = "P@ssw0rd_Pr0d_2024!"
    }
    api_keys = {
      stripe   = "sk_live_abc123def456"
      sendgrid = "SG.xyz789.uvw321"
      datadog  = "dd_api_key_prod_456789"
    }
  })
}

resource "aws_s3_object" "architecture_diagram" {
  bucket  = aws_s3_bucket.protected_data.id
  key     = "docs/infrastructure-architecture.txt"
  content = <<-EOT
Production Infrastructure Overview
==================================

VPC: 10.0.0.0/16
Public Subnets: 10.0.1.0/24, 10.0.2.0/24
Private Subnets: 10.0.10.0/24, 10.0.11.0/24

Database Tier:
- RDS PostgreSQL (Multi-AZ)
- ElastiCache Redis Cluster

Application Tier:
- ECS Fargate Tasks
- Application Load Balancer

Note: All production credentials stored in this S3 bucket.
Admin access required for retrieval.
EOT
}

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
  value = "TODO: Review IAM policies for developers. Self-service policy may be too broad. Need to restrict PutUserPolicy to only own user resources."

  tags = merge(local.common_tags, {
    Purpose = "Security team notes"
  })
}

module "audit_logging" {
  count  = var.enable_audit_logging ? 1 : 0
  source = "../modules/audit-logging"
  
  name_prefix = var.lab_prefix
  suffix      = random_string.suffix.result
  
  data_resources = [{
    type   = "AWS::S3::Object"
    values = ["${aws_s3_bucket.protected_data.arn}/*"]
  }]
  
  tags = local.common_tags
}
