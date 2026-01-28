data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

module "ami" {
  source = "../modules/ami-lookup"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  common_tags = {
    Environment  = "development"
    Destroyable  = "true"
    Application  = "url-inspector"
    AutoShutdown = "4hours"
  }
  instance_type = var.instance_type
}

module "vpc" {
  source = "../modules/lab-vpc"

  name_prefix       = var.lab_prefix
  vpc_cidr          = "10.0.0.0/16"
  aws_region        = var.aws_region
  allowed_ssh_cidrs = var.allowed_source_ips
  
  create_web_sg     = true
  allowed_web_cidrs = var.allowed_source_ips
  web_ports         = [8080]
  
  tags = local.common_tags
}