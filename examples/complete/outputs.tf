output "api_app_client_ids" {
  description = "Resource API application client ids."
  value       = module.api_app.client_ids
}

output "api_app_published_app_role_ids" {
  description = "Resolved app role ids published by the resource API, keyed by role name."
  value       = module.api_app.published_app_role_ids
}

output "api_app_published_scope_ids" {
  description = "Resolved permission scope ids published by the resource API, keyed by scope name."
  value       = module.api_app.published_permission_scope_ids
}

output "client_app_client_ids" {
  description = "Client application client ids."
  value       = module.client_app.client_ids
}

output "client_app_secret_values" {
  description = "Generated client secret values for the client application."
  value       = module.client_app.client_secret_values
  sensitive   = true
}

output "client_app_service_principal_object_ids" {
  description = "Client application service principal object ids."
  value       = module.client_app.service_principal_object_ids
}
