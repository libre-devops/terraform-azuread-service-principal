output "application_ids" {
  description = "Map of service principal key to the application registration resource id (the /applications/{objectId} form used as application_id by child resources)."
  value       = { for k, v in azuread_application_registration.this : k => v.id }
}

output "application_ids_zipmap" {
  description = "Map of service principal key to an object of its name and application id, for easy composition (matches the estate zipmap convention)."
  value       = { for k, v in azuread_application_registration.this : k => { name = v.display_name, id = v.id } }
}

output "application_object_ids" {
  description = "Map of service principal key to the application object id."
  value       = { for k, v in azuread_application_registration.this : k => v.object_id }
}

output "applications" {
  description = "Map of service principal key to the full set of useful application registration attributes."
  value = {
    for k, v in azuread_application_registration.this : k => {
      id                    = v.id
      object_id             = v.object_id
      client_id             = v.client_id
      display_name          = v.display_name
      publisher_domain      = v.publisher_domain
      disabled_by_microsoft = v.disabled_by_microsoft
    }
  }
}

output "client_certificate_key_ids" {
  description = "Map of \"<spn>|<certificate>\" key to the certificate key id."
  value       = { for k, v in azuread_application_certificate.this : k => v.key_id }
}

output "client_ids" {
  description = "Map of service principal key to the application client id (also called the application id / appId)."
  value       = { for k, v in azuread_application_registration.this : k => v.client_id }
}

output "client_secret_values" {
  description = "Map of \"<spn>|<secret>\" key to just the generated secret value."
  sensitive   = true
  value       = { for k, v in azuread_application_password.this : k => v.value }
}

output "client_secrets" {
  description = "Map of \"<spn>|<secret>\" key to the secret key id, value and display name. Store these in a secret manager; they are only shown at creation."
  sensitive   = true
  value = {
    for k, v in azuread_application_password.this : k => {
      key_id       = v.key_id
      value        = v.value
      display_name = v.display_name
    }
  }
}

output "federated_credential_ids" {
  description = "Map of \"<spn>|<credential>\" key to the federated identity credential id."
  value       = { for k, v in azuread_application_federated_identity_credential.this : k => v.credential_id }
}

output "flexible_federated_credential_ids" {
  description = "Map of \"<spn>|<credential>\" key to the flexible federated identity credential id."
  value       = { for k, v in azuread_application_flexible_federated_identity_credential.this : k => v.credential_id }
}

output "published_app_role_ids" {
  description = "Map of service principal key to a map of app role logical name to its resolved role id."
  value = {
    for k, v in var.service_principals : k => {
      for rk in keys(v.app_roles) : rk => azuread_application_app_role.this["${k}|${rk}"].role_id
    }
  }
}

output "published_permission_scope_ids" {
  description = "Map of service principal key to a map of permission scope logical name to its resolved scope id."
  value = {
    for k, v in var.service_principals : k => {
      for sk in keys(v.permission_scopes) : sk => azuread_application_permission_scope.this["${k}|${sk}"].scope_id
    }
  }
}

output "service_principal_object_ids" {
  description = "Map of service principal key to the service principal object id (the value to use in role assignments and group memberships)."
  value       = { for k, v in azuread_service_principal.this : k => v.object_id }
}

output "service_principals" {
  description = "Map of service principal key to the full set of useful service principal attributes."
  value = {
    for k, v in azuread_service_principal.this : k => {
      object_id                   = v.object_id
      display_name                = v.display_name
      type                        = v.type
      application_tenant_id       = v.application_tenant_id
      app_role_ids                = v.app_role_ids
      oauth2_permission_scope_ids = v.oauth2_permission_scope_ids
    }
  }
}
