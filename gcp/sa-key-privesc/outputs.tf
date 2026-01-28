output "developer_service_account_email" {
  description = "Email of the developer service account"
  value       = google_service_account.developer.email
}

output "developer_key_json" {
  description = "Service account key JSON (sensitive)"
  value       = base64decode(google_service_account_key.developer.private_key)
  sensitive   = true
}

output "protected_bucket_name" {
  description = "GCS bucket containing protected data"
  value       = google_storage_bucket.protected_data.name
}

output "gcp_project" {
  description = "GCP project ID"
  value       = var.gcp_project
}

output "gcp_region" {
  description = "GCP region"
  value       = var.gcp_region
}

output "lab_instructions" {
  description = "Instructions for configuring gcloud CLI"
  sensitive   = true
  value       = <<-EOT
Save the service account key to a file:

terraform output -raw developer_key_json > developer-key.json

Activate the service account:

gcloud auth activate-service-account --key-file=developer-key.json
gcloud config set project ${var.gcp_project}

Start by enumerating your permissions:

gcloud iam service-accounts list
gcloud projects get-iam-policy ${var.gcp_project} --flatten="bindings[].members" --filter="bindings.members:${google_service_account.developer.email}"
EOT
}

output "attack_chain_hint" {
  description = "Starting point for the lab"
  value       = "Begin by understanding what IAM permissions your service account has. What can you do to other service accounts?"
}
