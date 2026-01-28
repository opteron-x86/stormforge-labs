output "enabled_apis" {
  description = "List of APIs that were enabled"
  value       = [for api in google_project_service.apis : api.service]
}

output "ready" {
  description = "Dependency hook - use depends_on = [module.project_setup.ready]"
  value       = time_sleep.api_propagation.id
}
