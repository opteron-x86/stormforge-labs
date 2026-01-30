# ChainPulse - Crypto Price Oracle Aggregator
# Attack Chain: SSRF → IMDSv1 → Secrets Manager → RDS Exfiltration
# Difficulty: Medium
# Estimated Time: 60-90 minutes

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  backend "local" {}
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Environment  = "lab"
    Destroyable  = "true"
    Scenario     = "chainpulse"
    AutoShutdown = "4hours"
  }
  instance_type = "t3.micro"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "random_password" "db_password" {
  length  = 24
  special = false
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

module "ami" {
  source = "../modules/ami-lookup"
}

module "vpc" {
  source = "../modules/lab-vpc"

  name_prefix            = var.lab_prefix
  vpc_cidr               = "10.0.0.0/16"
  aws_region             = var.aws_region
  az_count               = 2
  allowed_ssh_cidrs      = var.allowed_source_ips
  enable_private_subnets = true
  enable_nat_gateway     = false

  create_web_sg     = true
  allowed_web_cidrs = var.allowed_source_ips
  web_ports         = [8080]

  tags = local.common_tags
}

resource "aws_security_group" "rds" {
  name        = "${var.lab_prefix}-rds-${random_string.suffix.result}"
  description = "PostgreSQL access from application tier"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL from webapp"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.vpc.web_security_group_id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.lab_prefix}-rds-sg"
  })
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.lab_prefix}-db-${random_string.suffix.result}"
  subnet_ids = module.vpc.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.lab_prefix}-db-subnet-group"
  })
}

resource "aws_db_instance" "trading_db" {
  identifier     = "${var.lab_prefix}-trading-${random_string.suffix.result}"
  engine         = "postgres"
  engine_version = "16.6"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "tradingdb"
  username = "chainpulse_svc"
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot     = true
  backup_retention_period = 0
  deletion_protection     = false

  publicly_accessible = false

  tags = merge(local.common_tags, {
    Name = "${var.lab_prefix}-trading-db"
  })
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.lab_prefix}/trading-db/credentials-${random_string.suffix.result}"
  recovery_window_in_days = 0

  tags = merge(local.common_tags, {
    Name = "${var.lab_prefix}-db-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = aws_db_instance.trading_db.username
    password = random_password.db_password.result
    host     = aws_db_instance.trading_db.address
    port     = aws_db_instance.trading_db.port
    dbname   = aws_db_instance.trading_db.db_name
    engine   = "postgres"
  })
}

resource "aws_s3_bucket" "app_files" {
  bucket        = "${var.lab_prefix}-app-${random_string.suffix.result}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = "${var.lab_prefix}-app-files"
  })
}

resource "aws_s3_bucket_public_access_block" "app_files" {
  bucket = aws_s3_bucket.app_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "app_py" {
  bucket = aws_s3_bucket.app_files.id
  key    = "app/app.py"
  source = "${path.module}/files/app.py"
  etag   = filemd5("${path.module}/files/app.py")
}

resource "aws_s3_object" "seed_sql" {
  bucket = aws_s3_bucket.app_files.id
  key    = "app/seed.sql"
  source = "${path.module}/files/seed.sql"
  etag   = filemd5("${path.module}/files/seed.sql")
}

resource "aws_iam_role" "webapp" {
  name = "${var.lab_prefix}-webapp-${random_string.suffix.result}"

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

resource "aws_iam_role_policy" "webapp_permissions" {
  name = "${var.lab_prefix}-webapp-policy"
  role = aws_iam_role.webapp.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3AppFilesRead"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app_files.arn,
          "${aws_s3_bucket.app_files.arn}/*"
        ]
      },
      {
        Sid    = "SSMSessionAccess"
        Effect = "Allow"
        Action = [
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:ResumeSession",
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus"
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMMessageAccess"
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
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
        Resource = "*"
      },
      {
        Sid    = "EC2Describe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.webapp.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "webapp" {
  name = "${var.lab_prefix}-webapp-${random_string.suffix.result}"
  role = aws_iam_role.webapp.name
}

resource "aws_instance" "webapp" {
  ami                    = module.ami.amazon_linux_2023_id
  instance_type          = local.instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [module.vpc.ssh_security_group_id, module.vpc.web_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.webapp.name
  key_name               = var.ssh_key_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional" # IMDSv1 enabled - vulnerable
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = base64encode(templatefile("${path.module}/userdata.tpl", {
    bucket_name = aws_s3_bucket.app_files.id
    db_host     = aws_db_instance.trading_db.address
    db_port     = aws_db_instance.trading_db.port
    db_name     = aws_db_instance.trading_db.db_name
    db_user     = aws_db_instance.trading_db.username
    db_password = random_password.db_password.result
  }))

  tags = merge(local.common_tags, {
    Name = "${var.lab_prefix}-webapp"
  })

  depends_on = [aws_db_instance.trading_db, aws_s3_object.app_py, aws_s3_object.seed_sql]

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}
