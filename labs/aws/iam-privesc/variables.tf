# variables.tf for IAM privilege escalation lab

variable "aws_region" {
  description = "AWS region for lab deployment"
  type        = string
  default     = ""
}

variable "lab_prefix" {
  description = "Prefix for all lab resources"
  type        = string
  default     = "lab-iam-privesc"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.lab_prefix))
    error_message = "Lab prefix must contain only lowercase letters, numbers, and hyphens."
  }
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

variable "allowed_source_ips" {
  description = "IP addresses allowed to access lab resources"
  type        = list(string)
  default     = []
}