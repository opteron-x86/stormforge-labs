variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "enable_api_sets" {
  description = "List of API sets to enable: storage, secrets, compute, functions, kubernetes, logging, bigquery, sql"
  type        = list(string)
  default     = []
}

variable "additional_apis" {
  description = "Additional APIs to enable beyond the standard sets"
  type        = list(string)
  default     = []
}

variable "api_wait_duration" {
  description = "Time to wait after enabling APIs for propagation"
  type        = string
  default     = "30s"
}
