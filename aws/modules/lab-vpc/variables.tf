variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.10.10.0/24"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 1
  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "AZ count must be between 1 and 3"
  }
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IPs to instances in public subnets"
  type        = bool
  default     = true
}

variable "enable_private_subnets" {
  description = "Create private subnets"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Create NAT gateway for private subnets (adds cost)"
  type        = bool
  default     = false
}

variable "create_ssh_sg" {
  description = "Create security group for SSH access"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed SSH access"
  type        = list(string)
  default     = []
}

variable "create_web_sg" {
  description = "Create security group for web access"
  type        = bool
  default     = false
}

variable "allowed_web_cidrs" {
  description = "CIDR blocks allowed web access"
  type        = list(string)
  default     = []
}

variable "web_ports" {
  description = "Ports to open for web security group"
  type        = list(number)
  default     = [80, 443, 8080]
}

variable "enable_s3_endpoint" {
  description = "Create VPC endpoint for S3 (reduces NAT costs)"
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}