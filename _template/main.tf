provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(var.default_tags, {
      Lab = "lab-name"
    })
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  name_prefix = "${var.lab_prefix}-labname-${random_id.suffix.hex}"
}

# Add resources here
