locals {
  # Core APIs required for most labs
  core_apis = [
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]

  # APIs by category - labs specify which categories they need
  api_sets = {
    storage = [
      "storage.googleapis.com",
    ]
    secrets = [
      "secretmanager.googleapis.com",
    ]
    compute = [
      "compute.googleapis.com",
    ]
    functions = [
      "cloudfunctions.googleapis.com",
      "cloudbuild.googleapis.com",
      "artifactregistry.googleapis.com",
    ]
    kubernetes = [
      "container.googleapis.com",
    ]
    logging = [
      "logging.googleapis.com",
      "monitoring.googleapis.com",
    ]
    bigquery = [
      "bigquery.googleapis.com",
    ]
    sql = [
      "sqladmin.googleapis.com",
    ]
  }

  requested_apis = distinct(flatten([
    for set_name in var.enable_api_sets : lookup(local.api_sets, set_name, [])
  ]))

  all_apis = distinct(concat(
    local.core_apis,
    local.requested_apis,
    var.additional_apis
  ))
}

resource "google_project_service" "apis" {
  for_each = toset(local.all_apis)

  project                    = var.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "time_sleep" "api_propagation" {
  depends_on      = [google_project_service.apis]
  create_duration = var.api_wait_duration
}
