```hcl
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
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | n/a |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_application.spn](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_federated_identity_credential.federated_cred](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_federated_identity_credential) | resource |
| [azuread_application_password.client_secret](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_service_principal.enterprise_app](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal_password.client_secret](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal_password) | resource |
| [azurerm_key_vault_secret.spn_kv_secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_spns"></a> [spns](#input\_spns) | The list of SPNs to be made | <pre>list(object({<br>    spn_name                            = string<br>    identifier_uris                     = optional(list(string))<br>    create_corresponding_enterprise_app = optional(bool, true)<br>    create_federated_credential         = optional(bool, false)<br>    create_client_secret                = optional(bool, false)<br>    federated_credential_display_name   = optional(string)<br>    federated_credential_description    = optional(string)<br>    federated_credential_audiences      = optional(list(string))<br>    federated_credential_issuer         = optional(string)<br>    federated_credential_subject        = optional(string)<br>    client_secret_display_name          = optional(string)<br>    client_secret_start_date            = optional(string)<br>    client_secret_end_date              = optional(string)<br>    attempt_put_spn_secret_in_kv        = optional(bool, false)<br>    key_vault_id                        = optional(string)<br>    description                         = optional(string)<br>    device_only_auth_enabled            = optional(bool, false)<br>    fallback_public_client_enabled      = optional(bool, false)<br>    group_membership_claims             = optional(list(string))<br>    logo_image                          = optional(string)<br>    marketing_url                       = optional(string)<br>    notes                               = optional(string)<br>    oauth2_post_response_required       = optional(bool, false)<br>    owners                              = optional(list(string))<br>    prevent_duplicate_names             = optional(bool, false)<br>    privacy_statement_url               = optional(string)<br>    required_resource_access = optional(list(object({<br>      resource_app_id = string<br>      resource_access = list(object({<br>        id   = string<br>        type = string<br>      }))<br>    })))<br>    service_management_reference = optional(string)<br>    sign_in_audience             = optional(string)<br>    single_page_application = optional(object({<br>      redirect_uris = list(string)<br>    }))<br>    support_url          = optional(string)<br>    tags                 = optional(list(string))<br>    template_id          = optional(string)<br>    terms_of_service_url = optional(string)<br>    web = optional(object({<br>      redirect_uris = list(string)<br>      logout_url    = optional(string)<br>      homepage_url  = optional(string)<br>      implicit_grant = optional(object({<br>        access_token_issuance_enabled = bool<br>        id_token_issuance_enabled     = bool<br><br>      }))<br>    }))<br>    api = optional(object({<br>      known_client_applications = list(string)<br>      mapped_claims_enabled     = optional(bool, false)<br>      oauth2_permission_scope = optional(list(object({<br>        admin_consent_description  = string<br>        admin_consent_display_name = string<br>        id                         = string<br>        type                       = optional(string, "User")<br>        user_consent_description   = optional(string)<br>        user_consent_display_name  = optional(string)<br>        value                      = optional(string)<br>        enabled                    = optional(bool, true)<br>      })))<br>      requested_access_token_version = optional(number, 1)<br>    }))<br>    app_role = optional(list(object({<br>      allowed_member_types = list(string)<br>      description          = string<br>      display_name         = string<br>      id                   = string<br>      value                = optional(string)<br>      enabled              = optional(bool, true)<br>    })))<br>    feature_tags = optional(object({<br>      custom_single_sign_on = optional(bool, false)<br>      enterprise            = optional(bool, false)<br>      gallery               = optional(bool, false)<br>      hide                  = optional(bool, false)<br>    }))<br>    optional_claims = optional(object({<br>      access_token = list(object({<br>        name                  = string<br>        essential             = optional(bool)<br>        additional_properties = optional(list(string))<br>        source                = optional(string)<br>      }))<br>      id_token = list(object({<br>        name                  = string<br>        essential             = optional(bool)<br>        additional_properties = optional(list(string))<br>        source                = optional(string)<br>      }))<br>      saml2_token = list(object({<br>        name                  = string<br>        essential             = optional(bool)<br>        additional_properties = optional(list(string))<br>        source                = optional(string)<br>      }))<br>    }))<br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_role_ids"></a> [app\_role\_ids](#output\_app\_role\_ids) | A mapping of application role display names to their corresponding IDs. This is useful for referencing app roles in other resources within your Terraform configuration. |
| <a name="output_app_roles"></a> [app\_roles](#output\_app\_roles) | Lists app roles published by the associated application. |
| <a name="output_application_tenant_id"></a> [application\_tenant\_id](#output\_application\_tenant\_id) | The tenant ID where the associated application is registered. |
| <a name="output_client_id"></a> [client\_id](#output\_client\_id) | The Client ID for each application. This is a unique identifier for the application in Azure AD and is used in various authentication and authorization flows. |
| <a name="output_client_secret_secret_id"></a> [client\_secret\_secret\_id](#output\_client\_secret\_secret\_id) | The id of the secret generated |
| <a name="output_client_secret_value"></a> [client\_secret\_value](#output\_client\_secret\_value) | The secret of the client secret created |
| <a name="output_display_name"></a> [display\_name](#output\_display\_name) | The display name of the application associated with this service principal. |
| <a name="output_federated_credential_id"></a> [federated\_credential\_id](#output\_federated\_credential\_id) | The credential ID of the federated credential |
| <a name="output_homepage_url"></a> [homepage\_url](#output\_homepage\_url) | Home page or landing page of the associated application. |
| <a name="output_id"></a> [id](#output\_id) | The Terraform resource ID for each application. This ID is unique to Terraform and can be used to reference the application resource in other parts of your Terraform configuration. |
| <a name="output_logout_url"></a> [logout\_url](#output\_logout\_url) | The URL that will be used by Microsoft's authorization service to log out an user. |
| <a name="output_oauth2_permission_scope_ids"></a> [oauth2\_permission\_scope\_ids](#output\_oauth2\_permission\_scope\_ids) | A mapping of OAuth2.0 permission scope values to scope IDs, as exposed by the associated application. |
| <a name="output_oauth2_permission_scopes"></a> [oauth2\_permission\_scopes](#output\_oauth2\_permission\_scopes) | Lists OAuth 2.0 delegated permission scopes exposed by the associated application. |
| <a name="output_object_id"></a> [object\_id](#output\_object\_id) | The object ID of the service principal. |
| <a name="output_redirect_uris"></a> [redirect\_uris](#output\_redirect\_uris) | Lists URLs where user tokens are sent for sign-in with the associated application. |
| <a name="output_saml_metadata_url"></a> [saml\_metadata\_url](#output\_saml\_metadata\_url) | The URL where the service exposes SAML metadata for federation. |
| <a name="output_service_principal_names"></a> [service\_principal\_names](#output\_service\_principal\_names) | Lists identifier URI(s), copied over from the associated application. |
| <a name="output_sign_in_audience"></a> [sign\_in\_audience](#output\_sign\_in\_audience) | The Microsoft account types that are supported for the associated application. |
| <a name="output_spN_client_secret_secret_id"></a> [spN\_client\_secret\_secret\_id](#output\_spN\_client\_secret\_secret\_id) | The id of the secret generated for the service principal resource |
| <a name="output_spn_app_role_ids"></a> [spn\_app\_role\_ids](#output\_spn\_app\_role\_ids) | A mapping of app role values to app role IDs, as published by the associated application, intended to be useful when referencing app roles in other resources in your configuration. |
| <a name="output_spn_client_secret_value"></a> [spn\_client\_secret\_value](#output\_spn\_client\_secret\_value) | The secret of the client secret created for the service principal resource |
| <a name="output_type"></a> [type](#output\_type) | Identifies whether the service principal represents an application or a managed identity, indicating the principal's purpose and capabilities. |
