variable "use_shared_cloudtrail" {
  description = "Use existing shared CloudTrail trail instead of creating new"
  type        = bool
  default     = true
}

variable "shared_cloudtrail_name" {
  description = "Name of shared CloudTrail trail (if use_shared_cloudtrail=true)"
  type        = string
  default     = ""
}

variable "shared_cloudtrail_bucket" {
  description = "S3 bucket name for shared CloudTrail logs"
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "suffix" {
  description = "Unique suffix for globally namespaced resources"
  type        = string
}

variable "include_global_events" {
  description = "Include IAM and STS events from us-east-1"
  type        = bool
  default     = true
}

variable "multi_region" {
  description = "Enable multi-region trail"
  type        = bool
  default     = false
}

variable "include_management_events" {
  description = "Log management events (API calls)"
  type        = bool
  default     = true
}

variable "read_write_type" {
  description = "Type of events to log: All, ReadOnly, or WriteOnly"
  type        = string
  default     = "All"
  validation {
    condition     = contains(["All", "ReadOnly", "WriteOnly"], var.read_write_type)
    error_message = "Must be All, ReadOnly, or WriteOnly"
  }
}

variable "data_resources" {
  description = "Data resources to log (S3, Lambda, etc.)"
  type = list(object({
    type   = string
    values = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}