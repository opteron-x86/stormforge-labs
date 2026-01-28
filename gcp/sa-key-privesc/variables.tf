variable "gcp_project" {
  description = "GCP project ID for lab deployment"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for lab deployment"
  type        = string
  default     = "us-east4"
}

variable "lab_prefix" {
  description = "Prefix for all lab resources"
  type        = string
  default     = "lab-iam-privesc"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.lab_prefix))
    error_message = "Lab prefix must start with a letter and contain only lowercase letters, numbers, and hyphens."
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
  description = "Enable Cloud Audit Logs for data access"
  type        = bool
  default     = false
}

variable "default_labels" {
  description = "Labels applied to all resources"
  type        = map(string)
  default     = {}
}
