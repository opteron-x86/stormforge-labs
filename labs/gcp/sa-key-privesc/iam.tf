resource "google_service_account" "developer" {
  account_id   = "${var.lab_prefix}-developer-${random_string.suffix.result}"
  display_name = "Developer Service Account"
  description  = "Service account for application development"
}

resource "google_service_account_key" "developer" {
  service_account_id = google_service_account.developer.name
}

resource "google_project_iam_member" "developer_iam_viewer" {
  project = var.gcp_project
  role    = "roles/iam.serviceAccountViewer"
  member  = "serviceAccount:${google_service_account.developer.email}"
}

resource "google_project_iam_member" "developer_secret_accessor" {
  project = var.gcp_project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.developer.email}"
}

resource "google_project_iam_member" "developer_storage_viewer" {
  project = var.gcp_project
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.developer.email}"

  condition {
    title       = "NonProtectedBucketsOnly"
    description = "Exclude protected data bucket"
    expression  = "!resource.name.startsWith('projects/_/buckets/${google_storage_bucket.protected_data.name}')"
  }
}

resource "google_project_iam_member" "developer_browser" {
  project = var.gcp_project
  role    = "roles/browser"
  member  = "serviceAccount:${google_service_account.developer.email}"
}

resource "google_project_iam_member" "developer_secret_viewer" {
  project = var.gcp_project
  role    = "roles/secretmanager.viewer"
  member  = "serviceAccount:${google_service_account.developer.email}"
}

resource "google_project_iam_member" "developer_key_admin" {
  project = var.gcp_project
  role    = "roles/iam.serviceAccountKeyAdmin"
  member  = "serviceAccount:${google_service_account.developer.email}"
}

resource "google_service_account" "admin_automation" {
  account_id   = "${var.lab_prefix}-admin-auto-${random_string.suffix.result}"
  display_name = "Admin Automation Service Account"
  description  = "Automated administrative tasks"
}

resource "google_project_iam_member" "admin_storage_admin" {
  project = var.gcp_project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.admin_automation.email}"
}

resource "google_project_iam_member" "admin_secret_admin" {
  project = var.gcp_project
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:${google_service_account.admin_automation.email}"
}
