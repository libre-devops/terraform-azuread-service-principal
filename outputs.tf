output "app_role_ids" {
  value       = { for k, app in azuread_application.spn : k => { for role in app.app_role : role.display_name => role.id } }
  description = "A mapping of application role display names to their corresponding IDs. This is useful for referencing app roles in other resources within your Terraform configuration."
}

output "app_roles" {
  value       = { for k, sp in azuread_service_principal.enterprise_app : k => sp.app_roles }
  description = "Lists app roles published by the associated application."
}

output "application_tenant_id" {
  value       = { for k, sp in azuread_service_principal.enterprise_app : k => sp.application_tenant_id }
  description = "The tenant ID where the associated application is registered."
}

output "client_id" {
  value       = { for k, app in azuread_application.spn : k => app.client_id }
  description = "The Client ID for each application. This is a unique identifier for the application in Azure AD and is used in various authentication and authorization flows."
}

output "client_secret_secret_id" {
  value       = { for k, sp in azuread_application_password.client_secret : k => sp.key_id }
  description = "The id of the secret generated"
}

output "client_secret_value" {
  value       = { for k, sp in azuread_application_password.client_secret : k => sp.value }
  description = "The secret of the client secret created"
}

output "display_name" {
  value       = { for k, sp in azuread_service_principal.enterprise_app : k => sp.display_name }
  description = "The display name of the application associated with this service principal."
}

output "federated_credential_id" {
  value       = { for k, sp in azuread_application_federated_identity_credential.federated_cred : k => sp.credential_id }
  description = "The credential ID of the federated credential"
}

output "homepage_url" {
  value       = { for k, sp in azuread_service_principal.enterprise_app : k => sp.homepage_url }
  description = "Home page or landing page of the associated application."
}

output "id" {
  value       = { for k, app in azuread_application.spn : k => app.id }
  description = "The Terraform resource ID for each application. This ID is unique to Terraform and can be used to reference the application resource in other parts of your Terraform configuration."
}

output "logout_url" {
  value       = { for k, sp in azuread_service_principal.enterprise_app : k => sp.logout_url }
  description = "The URL that will be used by Microsoft's authorization service to log out an user."
}

output "oauth2_permission_scope_ids" {
  value = {
    for k, sp in azuread_service_principal.enterprise_app : k =>
    { for scope in sp.oauth2_permission_scopes : scope.value => scope.id }
  }
  description = "A mapping of OAuth2.0 permission scope values to scope IDs, as exposed by the associated application."
}

output "oauth2_permission_scopes" {
  value       = { for k, sp in azuread_service_principal.enterprise_app : k => sp.oauth2_permission_scopes }
  description = "Lists OAuth 2.0 delegated permission scopes exposed by the associated application."
}

output "object_id" {
  value       = { for k, sp in azuread_service_principal.enterprise_app : k => sp.object_id }
  description = "The object ID of the service principal."
}

output "redirect_uris" {
  value       = { for k, sp in azuread_service_principal.enterprise_app : k => sp.redirect_uris }
  description = "Lists URLs where user tokens are sent for sign-in with the associated application."
}

output "saml_metadata_url" {
  value       = { for k, sp in azuread_service_principal.enterprise_app : k => sp.saml_metadata_url }
  description = "The URL where the service exposes SAML metadata for federation."
}

output "service_principal_names" {
  value       = { for k, sp in azuread_service_principal.enterprise_app : k => sp.service_principal_names }
  description = "Lists identifier URI(s), copied over from the associated application."
}

output "sign_in_audience" {
  value       = { for k, sp in azuread_service_principal.enterprise_app : k => sp.sign_in_audience }
  description = "The Microsoft account types that are supported for the associated application."
}

output "spn_app_role_ids" {
  value       = { for k, sp in azuread_service_principal.enterprise_app : k => sp.app_role_ids }
  description = "A mapping of app role values to app role IDs, as published by the associated application, intended to be useful when referencing app roles in other resources in your configuration."
}

output "spN_client_secret_secret_id" {
  value       = { for k, sp in azuread_service_principal_password.client_secret : k => sp.key_id }
  description = "The id of the secret generated for the service principal resource"
}

output "spn_client_secret_value" {
  value       = { for k, sp in azuread_service_principal_password.client_secret : k => sp.value }
  description = "The secret of the client secret created for the service principal resource"
}

output "type" {
  value       = { for k, sp in azuread_service_principal.enterprise_app : k => sp.type }
  description = "Identifies whether the service principal represents an application or a managed identity, indicating the principal's purpose and capabilities."
}
