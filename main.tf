data "azuread_client_config" "current" {}

resource "azuread_application" "spn" {
  for_each                       = { for k, v in var.spns : k => v }
  display_name                   = each.value.spn_name
  identifier_uris                = each.value.identifier_uris
  description                    = each.value.description
  device_only_auth_enabled       = each.value.device_only_auth_enabled
  fallback_public_client_enabled = each.value.fallback_public_client_enabled
  group_membership_claims        = each.value.group_membership_claims
  logo_image                     = each.value.logo_image
  marketing_url                  = each.value.marketing_url
  notes                          = each.value.notes
  oauth2_post_response_required  = each.value.oauth2_post_response_required
  owners                         = each.value.owners
  sign_in_audience               = each.value.sign_in_audience
  prevent_duplicate_names        = each.value.prevent_duplicate_names
  service_management_reference   = each.value.service_management_reference
  support_url                    = each.value.support_url
  tags                           = each.value.tags
  template_id                    = each.value.template_id
  terms_of_service_url           = each.value.terms_of_service_url

  dynamic "api" {
    for_each = each.value.api != null ? [each.value.api] : []
    content {
      mapped_claims_enabled          = api.value.mapped_claims_enabled
      requested_access_token_version = api.value.requested_access_token_version
      known_client_applications      = api.value.known_client_applications

      dynamic "oauth2_permission_scope" {
        for_each = api.value.oauth2_permission_scope != null ? api.value.oauth2_permission_scope : []
        content {
          admin_consent_description  = oauth2_permission_scope.value.admin_consent_description
          admin_consent_display_name = oauth2_permission_scope.value.admin_consent_display_name
          id                         = oauth2_permission_scope.value.id
          type                       = oauth2_permission_scope.value.type
          user_consent_description   = oauth2_permission_scope.value.user_consent_description
          user_consent_display_name  = oauth2_permission_scope.value.user_consent_display_name
          value                      = oauth2_permission_scope.value.value
          enabled                    = oauth2_permission_scope.value.enabled
        }
      }
    }
  }

  dynamic "app_role" {
    for_each = each.value.app_role != null ? each.value.app_role : []
    content {
      allowed_member_types = app_role.value.allowed_member_types
      description          = app_role.value.description
      display_name         = app_role.value.display_name
      id                   = app_role.value.id
      enabled              = app_role.value.enabled
    }
  }

  dynamic "feature_tags" {
    for_each = each.value.feature_tags != null ? [each.value.feature_tags] : []
    content {
      custom_single_sign_on = feature_tags.value.custom_single_sign_on
      enterprise            = feature_tags.value.enterprise
      gallery               = feature_tags.value.gallery
      hide                  = feature_tags.value.hide
    }
  }

  dynamic "optional_claims" {
    for_each = each.value.optional_claims != null ? [each.value.optional_claims] : []
    content {

      dynamic "access_token" {
        for_each = optional_claims.value.access_token != null ? optional_claims.value.access_token : []
        content {
          name                  = access_token.value.name
          essential             = access_token.value.essential
          additional_properties = access_token.value.additional_properties
          source                = access_token.value.source
        }
      }

      dynamic "id_token" {
        for_each = optional_claims.value.id_token != null ? optional_claims.value.id_token : []
        content {
          name                  = id_token.value.name
          essential             = id_token.value.essential
          additional_properties = id_token.value.additional_properties
          source                = id_token.value.source
        }
      }

      dynamic "saml2_token" {
        for_each = optional_claims.value.saml2_token != null ? optional_claims.value.saml2_token : []
        content {
          name                  = saml2_token.value.name
          essential             = saml2_token.value.essential
          additional_properties = saml2_token.value.additional_properties
          source                = saml2_token.value.source
        }
      }
    }
  }

  dynamic "required_resource_access" {
    for_each = each.value.required_resource_access != null ? each.value.required_resource_access : []
    content {
      resource_app_id = required_resource_access.value.resource_app_id

      dynamic "resource_access" {
        for_each = required_resource_access.value.resource_access != null ? required_resource_access.value.resource_access : []
        content {
          id   = resource_access.value.id
          type = resource_access.value.type
        }
      }
    }
  }

  dynamic "web" {
    for_each = each.value.web != null ? [each.value.web] : []
    content {
      redirect_uris = web.value.redirect_uris
      homepage_url  = web.value.homepage_url
      logout_url    = web.value.logout_url

      dynamic "implicit_grant" {
        for_each = web.value.implicit_grant != null ? [web.value.implicit_grant] : []
        content {
          access_token_issuance_enabled = implicit_grant.value.access_token_issuance_enabled
          id_token_issuance_enabled     = implicit_grant.value.id_token_issuance_enabled
        }
      }
    }
  }
}

resource "azuread_service_principal" "enterprise_app" {
  for_each = { for k, v in var.spns : k => v if v.create_corresponding_enterprise_app == true }

  client_id    = azuread_application.spn[each.key].client_id
  use_existing = true
}

resource "azuread_application_federated_identity_credential" "federated_cred" {

  for_each = { for k, v in var.spns : k => v if v.create_federated_credential == true }

  application_id = azuread_application.spn[each.key].id
  display_name   = each.value.federated_credential_display_name
  description    = each.value.federated_credential_description
  audiences      = each.value.federated_credential_audiences
  issuer         = each.value.federated_credential_issuer
  subject        = each.value.federated_credential_subject
}

resource "azuread_application_password" "client_secret" {
  for_each = { for k, v in var.spns : k => v if v.create_client_secret == true }

  application_id = azuread_application.spn[each.key].id
  display_name   = each.value.client_secret_display_name != null ? each.value.client_secret_display_name : "spn-secret-${azuread_service_principal.enterprise_app[each.key].display_name}"
  start_date     = each.value.client_secret_start_date
  end_date       = each.value.client_secret_end_date
}

resource "azuread_service_principal_password" "client_secret" {
  for_each = { for k, v in var.spns : k => v if v.create_client_secret == true && v.create_corresponding_enterprise_app == true }

  service_principal_id = azuread_service_principal.enterprise_app[each.key].object_id

  display_name = each.value.client_secret_display_name != null ? each.value.client_secret_display_name : "spn-secret-${azuread_service_principal.enterprise_app[each.key].display_name}"
  start_date   = each.value.client_secret_start_date
  end_date     = each.value.client_secret_end_date
}

resource "azurerm_key_vault_secret" "spn_kv_secret" {
  for_each        = { for k, v in var.spns : k => v if v.create_client_secret == true && v.create_corresponding_enterprise_app == true && v.attempt_put_spn_secret_in_kv == true && v.client_secret_end_date != null }
  name            = azuread_service_principal_password.client_secret[each.key].display_name
  value           = azuread_service_principal_password.client_secret[each.key].value
  key_vault_id    = each.value.key_vault_id
  content_type    = "text/plain"
  expiration_date = formatdate("YYYY-MM-DD'T'HH:mm:ss'Z'", each.value.client_secret_end_date)
}
