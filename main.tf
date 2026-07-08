data "azuread_client_config" "current" {}

locals {
  spns = var.service_principals

  # Any service principal asking for Microsoft Graph permissions gates the Graph data-source reads,
  # so callers that never touch Graph pay for no lookups.
  graph_requested = length([
    for k, v in local.spns : k
    if length(v.microsoft_graph_application_roles) > 0 || length(v.microsoft_graph_delegated_scopes) > 0
  ]) > 0

  # try() guards the count==0 index (Terraform evaluates both conditional branches, so a bare
  # data...[0] would blow up when no Graph permissions are requested). The reads happen at plan
  # time, so the resolved ids are known before apply.
  graph_client_id    = try(data.azuread_application_published_app_ids.well_known[0].result["MicrosoftGraph"], null)
  graph_sp_object_id = try(data.azuread_service_principal.msgraph[0].object_id, null)
  graph_app_role_ids = try(data.azuread_service_principal.msgraph[0].app_role_ids, {})
  graph_scope_ids    = try(data.azuread_service_principal.msgraph[0].oauth2_permission_scope_ids, {})

  # ---- Flattened child collections, keyed "<spn>|<child>" for stable for_each ----
  identifier_uris = merge([
    for k, v in local.spns : { for uri in v.identifier_uris : "${k}|${uri}" => { spn = k, uri = uri } }
  ]...)

  redirect_uris = merge([
    for k, v in local.spns : { for t, uris in v.redirect_uris : "${k}|${t}" => { spn = k, type = t, uris = uris } }
  ]...)

  app_owners = merge([
    for k, v in local.spns : { for o in v.owners : "${k}|${o}" => { spn = k, owner = o } }
  ]...)

  app_roles = merge([
    for k, v in local.spns : { for rk, r in v.app_roles : "${k}|${rk}" => merge(r, { spn = k }) }
  ]...)

  permission_scopes = merge([
    for k, v in local.spns : { for sk, s in v.permission_scopes : "${k}|${sk}" => merge(s, { spn = k }) }
  ]...)

  pre_authorized = merge([
    for k, v in local.spns : { for pk, p in v.pre_authorized_applications : "${k}|${pk}" => merge(p, { spn = k }) }
  ]...)

  api_permissions = merge([
    for k, v in local.spns : { for ak, a in v.api_permissions : "${k}|${ak}" => merge(a, { spn = k }) }
  ]...)

  client_secrets = merge([
    for k, v in local.spns : { for ck, c in v.client_secrets : "${k}|${ck}" => merge(c, { spn = k }) }
  ]...)

  client_certificates = merge([
    for k, v in local.spns : { for ck, c in v.client_certificates : "${k}|${ck}" => merge(c, { spn = k }) }
  ]...)

  federated_credentials = merge([
    for k, v in local.spns : { for fk, f in v.federated_credentials : "${k}|${fk}" => merge(f, { spn = k }) }
  ]...)

  flexible_federated_credentials = merge([
    for k, v in local.spns : { for fk, f in v.flexible_federated_credentials : "${k}|${fk}" => merge(f, { spn = k }) }
  ]...)

  # Generic (non-Graph) admin consent, only where a service principal exists to receive it.
  app_role_assignments = merge([
    for k, v in local.spns : { for ak, a in v.app_role_assignments : "${k}|${ak}" => merge(a, { spn = k }) }
    if v.create_service_principal
  ]...)

  delegated_grants = merge([
    for k, v in local.spns : { for dk, d in v.delegated_permission_grants : "${k}|${dk}" => merge(d, { spn = k }) }
    if v.create_service_principal
  ]...)

  # ---- Microsoft Graph shortcut, resolved to ids ----
  graph_api_access = {
    for k, v in local.spns : k => {
      role_ids  = [for n in v.microsoft_graph_application_roles : local.graph_app_role_ids[n]]
      scope_ids = [for n in v.microsoft_graph_delegated_scopes : local.graph_scope_ids[n]]
    }
    if length(v.microsoft_graph_application_roles) > 0 || length(v.microsoft_graph_delegated_scopes) > 0
  }

  # One app-role assignment per requested Graph application permission (tenant-wide admin consent).
  graph_app_role_grants = merge([
    for k, v in local.spns : {
      for n in v.microsoft_graph_application_roles : "${k}|${n}" => { spn = k, app_role_id = local.graph_app_role_ids[n] }
    }
    if v.create_service_principal && v.microsoft_graph_grant_admin_consent && length(v.microsoft_graph_application_roles) > 0
  ]...)

  # One delegated grant per service principal carrying all requested Graph delegated scopes.
  graph_delegated_grants = {
    for k, v in local.spns : k => { claim_values = v.microsoft_graph_delegated_scopes }
    if v.create_service_principal && v.microsoft_graph_grant_admin_consent && length(v.microsoft_graph_delegated_scopes) > 0
  }
}

# Microsoft Graph well-known client id and service principal, read only when Graph perms are asked for.
data "azuread_application_published_app_ids" "well_known" {
  count = local.graph_requested ? 1 : 0
}

data "azuread_service_principal" "msgraph" {
  count     = local.graph_requested ? 1 : 0
  client_id = data.azuread_application_published_app_ids.well_known[0].result["MicrosoftGraph"]
}

# ---------------------------------------------------------------------------------------------------
# Application registration (the base object) and its granular configuration
# ---------------------------------------------------------------------------------------------------

resource "azuread_application_registration" "this" {
  for_each = local.spns

  display_name                           = coalesce(each.value.display_name, each.key)
  description                            = each.value.description
  sign_in_audience                       = each.value.sign_in_audience
  group_membership_claims                = each.value.group_membership_claims
  homepage_url                           = each.value.homepage_url
  logout_url                             = each.value.logout_url
  marketing_url                          = each.value.marketing_url
  notes                                  = each.value.notes
  privacy_statement_url                  = each.value.privacy_statement_url
  support_url                            = each.value.support_url
  terms_of_service_url                   = each.value.terms_of_service_url
  service_management_reference           = each.value.service_management_reference
  requested_access_token_version         = each.value.requested_access_token_version
  implicit_access_token_issuance_enabled = each.value.implicit_access_token_issuance_enabled
  implicit_id_token_issuance_enabled     = each.value.implicit_id_token_issuance_enabled
}

resource "azuread_application_fallback_public_client" "this" {
  for_each = { for k, v in local.spns : k => v if v.fallback_public_client_enabled != null }

  application_id = azuread_application_registration.this[each.key].id
  enabled        = each.value.fallback_public_client_enabled
}

resource "azuread_application_identifier_uri" "this" {
  for_each = local.identifier_uris

  application_id = azuread_application_registration.this[each.value.spn].id
  identifier_uri = each.value.uri
}

# The api://{clientId} identifier URI Azure always accepts (the portal's default Application ID URI).
resource "azuread_application_identifier_uri" "default" {
  for_each = { for k, v in local.spns : k => v if v.default_identifier_uri }

  application_id = azuread_application_registration.this[each.key].id
  identifier_uri = "api://${azuread_application_registration.this[each.key].client_id}"
}

resource "azuread_application_redirect_uris" "this" {
  for_each = local.redirect_uris

  application_id = azuread_application_registration.this[each.value.spn].id
  type           = each.value.type
  redirect_uris  = each.value.uris
}

resource "azuread_application_known_clients" "this" {
  for_each = { for k, v in local.spns : k => v if length(v.known_client_ids) > 0 }

  application_id   = azuread_application_registration.this[each.key].id
  known_client_ids = each.value.known_client_ids
}

resource "azuread_application_optional_claims" "this" {
  for_each = { for k, v in local.spns : k => v if v.optional_claims != null }

  application_id = azuread_application_registration.this[each.key].id

  dynamic "access_token" {
    for_each = each.value.optional_claims.access_token
    content {
      name                  = access_token.value.name
      source                = access_token.value.source
      essential             = access_token.value.essential
      additional_properties = access_token.value.additional_properties
    }
  }

  dynamic "id_token" {
    for_each = each.value.optional_claims.id_token
    content {
      name                  = id_token.value.name
      source                = id_token.value.source
      essential             = id_token.value.essential
      additional_properties = id_token.value.additional_properties
    }
  }

  dynamic "saml2_token" {
    for_each = each.value.optional_claims.saml2_token
    content {
      name                  = saml2_token.value.name
      source                = saml2_token.value.source
      essential             = saml2_token.value.essential
      additional_properties = saml2_token.value.additional_properties
    }
  }
}

resource "azuread_application_owner" "this" {
  for_each = local.app_owners

  application_id  = azuread_application_registration.this[each.value.spn].id
  owner_object_id = each.value.owner
}

# App roles and permission scopes get a stable random UUID when the caller does not pin one.
resource "random_uuid" "app_role" {
  for_each = { for key, r in local.app_roles : key => r if r.role_id == null }
}

resource "azuread_application_app_role" "this" {
  for_each = local.app_roles

  application_id       = azuread_application_registration.this[each.value.spn].id
  role_id              = each.value.role_id != null ? each.value.role_id : random_uuid.app_role[each.key].id
  allowed_member_types = each.value.allowed_member_types
  description          = each.value.description
  display_name         = each.value.display_name
  value                = each.value.value
}

resource "random_uuid" "permission_scope" {
  for_each = { for key, s in local.permission_scopes : key => s if s.scope_id == null }
}

resource "azuread_application_permission_scope" "this" {
  for_each = local.permission_scopes

  application_id             = azuread_application_registration.this[each.value.spn].id
  scope_id                   = each.value.scope_id != null ? each.value.scope_id : random_uuid.permission_scope[each.key].id
  admin_consent_description  = each.value.admin_consent_description
  admin_consent_display_name = each.value.admin_consent_display_name
  type                       = each.value.type
  user_consent_description   = coalesce(each.value.user_consent_description, each.value.admin_consent_description)
  user_consent_display_name  = coalesce(each.value.user_consent_display_name, each.value.admin_consent_display_name)
  value                      = each.value.value
}

resource "azuread_application_pre_authorized" "this" {
  for_each = local.pre_authorized

  application_id       = azuread_application_registration.this[each.value.spn].id
  authorized_client_id = each.value.authorized_client_id
  permission_ids       = each.value.permission_ids
}

resource "azuread_application_api_access" "this" {
  for_each = local.api_permissions

  application_id = azuread_application_registration.this[each.value.spn].id
  api_client_id  = each.value.api_client_id
  role_ids       = length(each.value.role_ids) > 0 ? each.value.role_ids : null
  scope_ids      = length(each.value.scope_ids) > 0 ? each.value.scope_ids : null
}

resource "azuread_application_api_access" "graph" {
  for_each = local.graph_api_access

  application_id = azuread_application_registration.this[each.key].id
  api_client_id  = local.graph_client_id
  role_ids       = length(each.value.role_ids) > 0 ? each.value.role_ids : null
  scope_ids      = length(each.value.scope_ids) > 0 ? each.value.scope_ids : null
}

# ---------------------------------------------------------------------------------------------------
# Service principal and its credentials
# ---------------------------------------------------------------------------------------------------

resource "azuread_service_principal" "this" {
  for_each = { for k, v in local.spns : k => v if v.create_service_principal }

  client_id                     = azuread_application_registration.this[each.key].client_id
  account_enabled               = each.value.account_enabled
  app_role_assignment_required  = each.value.app_role_assignment_required
  description                   = each.value.service_principal_description
  owners                        = length(each.value.service_principal_owners) > 0 ? each.value.service_principal_owners : null
  alternative_names             = each.value.alternative_names
  login_url                     = each.value.login_url
  notes                         = each.value.service_principal_notes
  notification_email_addresses  = each.value.notification_email_addresses
  preferred_single_sign_on_mode = each.value.preferred_single_sign_on_mode
  tags                          = each.value.service_principal_tags
  use_existing                  = each.value.use_existing

  dynamic "feature_tags" {
    for_each = each.value.feature_tags != null ? [each.value.feature_tags] : []
    content {
      custom_single_sign_on = feature_tags.value.custom_single_sign_on
      enterprise            = feature_tags.value.enterprise
      gallery               = feature_tags.value.gallery
      hide                  = feature_tags.value.hide
    }
  }

  dynamic "saml_single_sign_on" {
    for_each = each.value.saml_single_sign_on_relay_state != null ? [each.value.saml_single_sign_on_relay_state] : []
    content {
      relay_state = saml_single_sign_on.value
    }
  }
}

resource "azuread_application_password" "this" {
  for_each = local.client_secrets

  application_id      = azuread_application_registration.this[each.value.spn].id
  display_name        = each.value.display_name
  start_date          = each.value.start_date
  end_date            = each.value.end_date
  end_date_relative   = each.value.end_date_relative
  rotate_when_changed = each.value.rotate_when_changed
}

resource "azuread_application_certificate" "this" {
  for_each = local.client_certificates

  application_id    = azuread_application_registration.this[each.value.spn].id
  type              = each.value.type
  value             = each.value.value
  encoding          = each.value.encoding
  start_date        = each.value.start_date
  end_date          = each.value.end_date
  end_date_relative = each.value.end_date_relative
  key_id            = each.value.key_id
}

resource "azuread_application_federated_identity_credential" "this" {
  for_each = local.federated_credentials

  application_id = azuread_application_registration.this[each.value.spn].id
  display_name   = each.value.display_name
  audiences      = each.value.audiences
  issuer         = each.value.issuer
  subject        = each.value.subject
  description    = each.value.description
}

resource "azuread_application_flexible_federated_identity_credential" "this" {
  for_each = local.flexible_federated_credentials

  application_id             = azuread_application_registration.this[each.value.spn].id
  display_name               = each.value.display_name
  audience                   = each.value.audience
  issuer                     = each.value.issuer
  claims_matching_expression = each.value.claims_matching_expression
  description                = each.value.description
}

# ---------------------------------------------------------------------------------------------------
# Admin consent: app role assignments (application permissions) and delegated permission grants
# ---------------------------------------------------------------------------------------------------

resource "azuread_app_role_assignment" "this" {
  for_each = local.app_role_assignments

  app_role_id         = each.value.app_role_id
  principal_object_id = azuread_service_principal.this[each.value.spn].object_id
  resource_object_id  = each.value.resource_object_id
}

resource "azuread_app_role_assignment" "graph" {
  for_each = local.graph_app_role_grants

  app_role_id         = each.value.app_role_id
  principal_object_id = azuread_service_principal.this[each.value.spn].object_id
  resource_object_id  = local.graph_sp_object_id
}

resource "azuread_service_principal_delegated_permission_grant" "this" {
  for_each = local.delegated_grants

  service_principal_object_id          = azuread_service_principal.this[each.value.spn].object_id
  resource_service_principal_object_id = each.value.resource_service_principal_object_id
  claim_values                         = each.value.claim_values
  user_object_id                       = each.value.user_object_id
}

resource "azuread_service_principal_delegated_permission_grant" "graph" {
  for_each = local.graph_delegated_grants

  service_principal_object_id          = azuread_service_principal.this[each.key].object_id
  resource_service_principal_object_id = local.graph_sp_object_id
  claim_values                         = each.value.claim_values
}
