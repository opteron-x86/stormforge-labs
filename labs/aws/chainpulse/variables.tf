variable "aws_region" {
  description = "AWS region for lab deployment"
  type        = string
  default     = ""
}

variable "lab_prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "chainpulse"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.lab_prefix))
    error_message = "Prefix must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "ssh_key_name" {
  description = "AWS SSH key pair name for EC2 access"
  type        = string
  default     = ""
}

variable "allowed_source_ips" {
  description = "CIDR blocks allowed to access lab resources"
  type        = list(string)
  validation {
    condition     = length(var.allowed_source_ips) > 0
    error_message = "At least one source IP must be specified"
  }
}
