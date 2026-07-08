output "client_ids" {
  description = "Application client ids, keyed by service principal name."
  value       = module.service_principal.client_ids
}

output "client_secret_values" {
  description = "Generated client secret values, keyed by \"<spn>|<secret>\"."
  value       = module.service_principal.client_secret_values
  sensitive   = true
}

output "service_principal_object_ids" {
  description = "Service principal object ids, keyed by service principal name."
  value       = module.service_principal.service_principal_object_ids
}
