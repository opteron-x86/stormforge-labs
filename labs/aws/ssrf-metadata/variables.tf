variable "aws_region" {
  description = "AWS region for lab deployment"
  type        = string
  default     = "us-east-1"
}

variable "allowed_source_ips" {
  description = "IP addresses allowed to access resources"
  type        = list(string)
  validation {
    condition     = length(var.allowed_source_ips) > 0
    error_message = "At least one allowed IP must be specified."
  }
}

variable "ssh_key_name" {
  description = "AWS SSH key pair name for EC2 access"
  type        = string
  default     = ""
}

variable "lab_prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "url-inspector"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.lab_prefix))
    error_message = "Prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "auto_shutdown_hours" {
  description = "Hours until automatic instance shutdown"
  type        = number
  default     = 4
  validation {
    condition     = var.auto_shutdown_hours >= 1 && var.auto_shutdown_hours <= 24
    error_message = "Auto shutdown must be between 1 and 24 hours."
  }
}

variable "enable_audit_logging" {
  description = "Enable CloudTrail audit logging"
  type        = bool
  default     = false
}

variable "enable_cost_controls" {
  description = "Enable automatic cost control measures"
  type        = bool
  default     = true
}

variable "lab_difficulty" {
  description = "Difficulty rating (1-10)"
  type        = number
  default     = 2
  validation {
    condition     = var.lab_difficulty >= 1 && var.lab_difficulty <= 10
    error_message = "Difficulty must be between 1 and 10."
  }
}