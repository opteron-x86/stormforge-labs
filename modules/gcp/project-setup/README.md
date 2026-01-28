# GCP Project Setup Module

Enables required GCP APIs and waits for propagation before lab resources are created.

## Usage

```hcl
module "project_setup" {
  source = "../../modules/gcp/project-setup"

  project_id      = var.gcp_project
  enable_api_sets = ["storage", "secrets"]
}

# Use the ready output to ensure APIs are enabled before creating resources
resource "google_service_account" "lab" {
  depends_on = [module.project_setup.ready]
  
  account_id   = "lab-sa"
  display_name = "Lab Service Account"
}
```

## API Sets

| Set | APIs Included |
|-----|---------------|
| `storage` | storage.googleapis.com |
| `secrets` | secretmanager.googleapis.com |
| `compute` | compute.googleapis.com |
| `functions` | cloudfunctions, cloudbuild, artifactregistry |
| `kubernetes` | container.googleapis.com |
| `logging` | logging, monitoring |
| `bigquery` | bigquery.googleapis.com |
| `sql` | sqladmin.googleapis.com |

Core APIs (always enabled):
- iam.googleapis.com
- iamcredentials.googleapis.com
- cloudresourcemanager.googleapis.com

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_id | GCP project ID | string | required |
| enable_api_sets | List of API sets to enable | list(string) | [] |
| additional_apis | Extra APIs beyond standard sets | list(string) | [] |
| api_wait_duration | Propagation wait time | string | "30s" |

## Outputs

| Name | Description |
|------|-------------|
| enabled_apis | List of enabled API names |
| ready | Dependency hook for other resources |
