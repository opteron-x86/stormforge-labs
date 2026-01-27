variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "lab_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "sf"
}

variable "allowed_source_ips" {
  description = "IPs allowed to access lab resources"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "default_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
