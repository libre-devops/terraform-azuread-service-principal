variable "service_principals" {
  description = <<-DESC
    Map of service principals to create, keyed by a stable logical name (the key is used as the
    default application display name and to build the flattened keys of every child resource, so
    keep it unique and meaningful). Each entry drives an application registration
    (azuread_application_registration) plus, optionally, a service principal and the full set of
    credentials, published roles/scopes, requested API permissions, owners and admin consent.

    The map(object) shape keeps callers declarative: name a service principal once and hang all of
    its configuration off that key. Everything except display_name is optional so the smallest call
    is a single key with an empty object.
  DESC

  type = map(object({
    # ---- Application registration core (azuread_application_registration) ----
    display_name                           = optional(string)
    description                            = optional(string)
    sign_in_audience                       = optional(string, "AzureADMyOrg")
    group_membership_claims                = optional(list(string))
    homepage_url                           = optional(string)
    logout_url                             = optional(string)
    marketing_url                          = optional(string)
    notes                                  = optional(string)
    privacy_statement_url                  = optional(string)
    support_url                            = optional(string)
    terms_of_service_url                   = optional(string)
    service_management_reference           = optional(string)
    requested_access_token_version         = optional(number, 2)
    implicit_access_token_issuance_enabled = optional(bool)
    implicit_id_token_issuance_enabled     = optional(bool)

    # ---- Fallback public client (azuread_application_fallback_public_client) ----
    # Leave null to let Azure decide (recommended). Set true/false to pin it.
    fallback_public_client_enabled = optional(bool)

    # ---- Identifier URIs (azuread_application_identifier_uri, one resource per URI) ----
    # Custom identifier URIs must sit on a verified publisher domain (or be the api://{clientId}
    # form). Set default_identifier_uri to have the module mint api://{client_id} for you, which
    # Azure always accepts because the application inherently owns its own client id.
    identifier_uris        = optional(set(string), [])
    default_identifier_uri = optional(bool, false)

    # ---- Redirect URIs (azuread_application_redirect_uris, one resource per type) ----
    # Keyed by URI type: "Web", "SPA" or "PublicClient".
    redirect_uris = optional(map(set(string)), {})

    # ---- Known client applications (azuread_application_known_clients) ----
    known_client_ids = optional(set(string), [])

    # ---- Owners of the application registration (azuread_application_owner, one per) ----
    owners = optional(set(string), [])

    # ---- Optional claims (azuread_application_optional_claims) ----
    optional_claims = optional(object({
      access_token = optional(list(object({
        name                  = string
        source                = optional(string)
        essential             = optional(bool)
        additional_properties = optional(list(string))
      })), [])
      id_token = optional(list(object({
        name                  = string
        source                = optional(string)
        essential             = optional(bool)
        additional_properties = optional(list(string))
      })), [])
      saml2_token = optional(list(object({
        name                  = string
        source                = optional(string)
        essential             = optional(bool)
        additional_properties = optional(list(string))
      })), [])
    }))

    # ---- App roles this application PUBLISHES (azuread_application_app_role) ----
    # Keyed by a logical name. role_id is optional: when omitted a stable random UUID is generated
    # and kept in state, so callers declare roles by intent, not by hand-minted GUIDs.
    app_roles = optional(map(object({
      allowed_member_types = list(string)
      description          = string
      display_name         = string
      value                = optional(string)
      role_id              = optional(string)
    })), {})

    # ---- OAuth2 permission scopes this application PUBLISHES (azuread_application_permission_scope) ----
    permission_scopes = optional(map(object({
      admin_consent_description  = string
      admin_consent_display_name = string
      value                      = string
      type                       = optional(string, "User")
      user_consent_description   = optional(string)
      user_consent_display_name  = optional(string)
      scope_id                   = optional(string)
    })), {})

    # ---- Pre-authorized client applications (azuread_application_pre_authorized) ----
    pre_authorized_applications = optional(map(object({
      authorized_client_id = string
      permission_ids       = list(string)
    })), {})

    # ---- API permissions this application REQUESTS, per resource API (azuread_application_api_access) ----
    # Keyed by a logical name. api_client_id is the resource API's client id (for Microsoft Graph
    # prefer the microsoft_graph_* shortcuts below). At least one of role_ids/scope_ids per entry.
    api_permissions = optional(map(object({
      api_client_id = string
      role_ids      = optional(set(string), [])
      scope_ids     = optional(set(string), [])
    })), {})

    # ---- Microsoft Graph shortcut ----
    # Declare Graph permissions by their published NAME (for example "User.Read.All"). The module
    # resolves the ids against the tenant's Microsoft Graph service principal, requests them on the
    # application, and (when microsoft_graph_grant_admin_consent is true and a service principal is
    # created) grants tenant-wide admin consent: application roles via azuread_app_role_assignment,
    # delegated scopes via azuread_service_principal_delegated_permission_grant.
    microsoft_graph_application_roles   = optional(set(string), [])
    microsoft_graph_delegated_scopes    = optional(set(string), [])
    microsoft_graph_grant_admin_consent = optional(bool, true)

    # ---- Generic admin consent escape hatches (any resource API) ----
    # Grant an app role (application permission) held by any resource service principal TO this
    # service principal (azuread_app_role_assignment). Use for non-Graph APIs, or the Graph
    # default role id 00000000-0000-0000-0000-000000000000.
    app_role_assignments = optional(map(object({
      resource_object_id = string
      app_role_id        = string
    })), {})

    # Grant delegated permissions (azuread_service_principal_delegated_permission_grant). Omit
    # user_object_id to consent for all users (admin consent).
    delegated_permission_grants = optional(map(object({
      resource_service_principal_object_id = string
      claim_values                         = set(string)
      user_object_id                       = optional(string)
    })), {})

    # ---- Service principal (azuread_service_principal) ----
    create_service_principal        = optional(bool, true)
    account_enabled                 = optional(bool, true)
    app_role_assignment_required    = optional(bool, false)
    service_principal_description   = optional(string)
    service_principal_owners        = optional(set(string), [])
    alternative_names               = optional(set(string))
    login_url                       = optional(string)
    service_principal_notes         = optional(string)
    notification_email_addresses    = optional(set(string))
    preferred_single_sign_on_mode   = optional(string)
    saml_single_sign_on_relay_state = optional(string)
    service_principal_tags          = optional(set(string))
    use_existing                    = optional(bool)
    feature_tags = optional(object({
      custom_single_sign_on = optional(bool, false)
      enterprise            = optional(bool, false)
      gallery               = optional(bool, false)
      hide                  = optional(bool, false)
    }))

    # ---- Client secrets (azuread_application_password, one per key) ----
    client_secrets = optional(map(object({
      display_name        = optional(string)
      start_date          = optional(string)
      end_date            = optional(string)
      end_date_relative   = optional(string)
      rotate_when_changed = optional(map(string))
    })), {})

    # ---- Client certificates (azuread_application_certificate, one per key) ----
    client_certificates = optional(map(object({
      value             = string
      type              = optional(string, "AsymmetricX509Cert")
      encoding          = optional(string, "pem")
      start_date        = optional(string)
      end_date          = optional(string)
      end_date_relative = optional(string)
      key_id            = optional(string)
    })), {})

    # ---- Federated identity credentials (azuread_application_federated_identity_credential) ----
    federated_credentials = optional(map(object({
      display_name = string
      issuer       = string
      subject      = string
      audiences    = optional(set(string), ["api://AzureADTokenExchange"])
      description  = optional(string)
    })), {})

    # ---- Flexible federated identity credentials (azuread_application_flexible_federated_identity_credential) ----
    flexible_federated_credentials = optional(map(object({
      display_name               = string
      issuer                     = string
      claims_matching_expression = string
      audience                   = optional(string, "api://AzureADTokenExchange")
      description                = optional(string)
    })), {})
  }))

  default = {}

  # sign_in_audience must be one of the supported values.
  validation {
    condition = alltrue([
      for k, v in var.service_principals :
      contains(["AzureADMyOrg", "AzureADMultipleOrgs", "AzureADandPersonalMicrosoftAccount", "PersonalMicrosoftAccount"], v.sign_in_audience)
    ])
    error_message = "sign_in_audience must be one of AzureADMyOrg, AzureADMultipleOrgs, AzureADandPersonalMicrosoftAccount or PersonalMicrosoftAccount."
  }

  # Access token version must be 1 or 2, and must be 2 for the personal-account audiences.
  validation {
    condition = alltrue([
      for k, v in var.service_principals :
      contains([1, 2], v.requested_access_token_version) &&
      (contains(["AzureADandPersonalMicrosoftAccount", "PersonalMicrosoftAccount"], v.sign_in_audience) ? v.requested_access_token_version == 2 : true)
    ])
    error_message = "requested_access_token_version must be 1 or 2, and must be 2 when sign_in_audience allows personal Microsoft accounts."
  }

  # group_membership_claims values are constrained by Graph.
  validation {
    condition = alltrue([
      for k, v in var.service_principals :
      v.group_membership_claims == null ? true : alltrue([
        for c in v.group_membership_claims :
        contains(["None", "SecurityGroup", "DirectoryRole", "ApplicationGroup", "All"], c)
      ])
    ])
    error_message = "group_membership_claims entries must be one of None, SecurityGroup, DirectoryRole, ApplicationGroup or All."
  }

  # Redirect URI collections are keyed by type; only Web, SPA and PublicClient are valid.
  validation {
    condition = alltrue([
      for k, v in var.service_principals :
      alltrue([for t in keys(v.redirect_uris) : contains(["Web", "SPA", "PublicClient"], t)])
    ])
    error_message = "redirect_uris keys must be one of Web, SPA or PublicClient."
  }

  # App role member types are constrained to User and/or Application.
  validation {
    condition = alltrue([
      for k, v in var.service_principals : alltrue([
        for rk, r in v.app_roles : alltrue([
          for m in r.allowed_member_types : contains(["User", "Application"], m)
        ])
      ])
    ])
    error_message = "app_roles allowed_member_types entries must be User and/or Application."
  }

  # Permission scope consent type is User or Admin.
  validation {
    condition = alltrue([
      for k, v in var.service_principals : alltrue([
        for sk, s in v.permission_scopes : contains(["User", "Admin"], s.type)
      ])
    ])
    error_message = "permission_scopes type must be either User or Admin."
  }

  # Certificate type and encoding must be values the provider accepts.
  validation {
    condition = alltrue([
      for k, v in var.service_principals : alltrue([
        for ck, c in v.client_certificates :
        contains(["AsymmetricX509Cert", "Symmetric"], c.type) && contains(["pem", "base64", "hex"], c.encoding)
      ])
    ])
    error_message = "client_certificates type must be AsymmetricX509Cert or Symmetric, and encoding must be pem, base64 or hex."
  }

  # api_permissions entries must request at least one role or scope (the provider rejects empty).
  validation {
    condition = alltrue([
      for k, v in var.service_principals : alltrue([
        for ak, a in v.api_permissions : length(a.role_ids) > 0 || length(a.scope_ids) > 0
      ])
    ])
    error_message = "each api_permissions entry must set at least one of role_ids or scope_ids."
  }

  # A service principal stores features as magic tags, so feature_tags and explicit tags are
  # mutually exclusive on the same principal.
  validation {
    condition = alltrue([
      for k, v in var.service_principals : !(v.feature_tags != null && v.service_principal_tags != null)
    ])
    error_message = "feature_tags and service_principal_tags cannot both be set on the same service principal."
  }
}
