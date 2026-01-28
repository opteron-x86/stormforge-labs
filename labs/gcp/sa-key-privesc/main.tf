resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  common_labels = merge(var.default_labels, {
    environment   = "lab"
    destroyable   = "true"
    scenario      = "sa-key-privilege-escalation"
    auto-shutdown = "24hours"
  })
}

data "google_project" "current" {}

module "project_setup" {
  source = "../../../modules/gcp/project-setup"

  project_id      = var.gcp_project
  enable_api_sets = ["iam", "storage", "secrets"]
}

resource "google_service_account" "attacker" {
  depends_on = [module.project_setup.ready]

  account_id   = "${var.lab_prefix}-attacker-${random_string.suffix.result}"
  display_name = "Attacker Service Account"
}


resource "google_storage_bucket" "protected_data" {
  name          = "${var.lab_prefix}-protected-${random_string.suffix.result}"
  location      = var.gcp_region
  force_destroy = true

  uniform_bucket_level_access = true

  labels = merge(local.common_labels, {
    data-classification = "confidential"
    owner               = "security-team"
  })
}

resource "google_storage_bucket_object" "financial_records" {
  bucket  = google_storage_bucket.protected_data.name
  name    = "financial/q4-2024-revenue.csv"
  content = <<-EOT
department,revenue,expenses,profit_margin
Engineering,2500000,1800000,28.0
Sales,3200000,900000,71.9
Marketing,800000,750000,6.3
Operations,1500000,1200000,20.0
EOT
}

resource "google_storage_bucket_object" "credentials" {
  bucket  = google_storage_bucket.protected_data.name
  name    = "secrets/production-credentials.json"
  content = jsonencode({
    database = {
      host     = "prod-db.internal.psychocorp.com"
      username = "admin"
      password = "P@ssw0rd_Pr0d_2026!"
    }
    api_keys = {
      stripe   = "sk_live_abc123def456"
      sendgrid = "SG.xyz789.uvw321"
      datadog  = "dd_api_key_prod_456789"
    }
  })
}

resource "google_storage_bucket_object" "architecture_diagram" {
  bucket  = google_storage_bucket.protected_data.name
  name    = "docs/infrastructure-architecture.txt"
  content = <<-EOT
Production Infrastructure Overview
==================================

VPC: 10.0.0.0/16
Public Subnets: 10.0.1.0/24, 10.0.2.0/24
Private Subnets: 10.0.10.0/24, 10.0.11.0/24

Database Tier:
- Cloud SQL PostgreSQL (HA configuration)
- Memorystore Redis Cluster

Application Tier:
- Cloud Run services
- Cloud Load Balancing

Note: All production credentials stored in this GCS bucket.
Admin service account access required for retrieval.
EOT
}

resource "google_secret_manager_secret" "protected_bucket_name" {
  secret_id = "${var.lab_prefix}-config-protected-bucket"

  replication {
    auto {}
  }

  labels = merge(local.common_labels, {
    purpose = "gcs-bucket-name"
  })
}

resource "google_secret_manager_secret_version" "protected_bucket_name" {
  secret      = google_secret_manager_secret.protected_bucket_name.id
  secret_data = google_storage_bucket.protected_data.name
}

resource "google_secret_manager_secret" "admin_sa_email" {
  secret_id = "${var.lab_prefix}-config-admin-automation-sa"

  replication {
    auto {}
  }

  labels = merge(local.common_labels, {
    purpose = "service-account-email"
  })
}

resource "google_secret_manager_secret_version" "admin_sa_email" {
  secret      = google_secret_manager_secret.admin_sa_email.id
  secret_data = google_service_account.admin_automation.email
}

resource "google_secret_manager_secret" "security_note" {
  secret_id = "${var.lab_prefix}-notes-security-review"

  replication {
    auto {}
  }

  labels = merge(local.common_labels, {
    purpose = "security-notes"
  })
}

resource "google_secret_manager_secret_version" "security_note" {
  secret      = google_secret_manager_secret.security_note.id
  secret_data = "TODO: Review IAM bindings for developer SA. The serviceAccountKeyAdmin role may be too broad."
}
