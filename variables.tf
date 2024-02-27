variable "spns" {
  description = "The list of SPNs to be made"
  type = list(object({
    spn_name                       = string
    identifier_uris                = list(string)
    description                    = optional(string)
    device_only_auth_enabled       = optional(bool, false)
    fallback_public_client_enabled = optional(bool, false)
    group_membership_claims        = optional(list(string))
    logo_image                     = optional(string)
    marketing_url                  = optional(string)
    notes                          = optional(string)
    oauth2_post_response_required  = optional(bool, false)
    owners                         = optional(list(string))
    prevent_duplicate_names        = optional(bool, false)
    privacy_statement_url          = optional(string)
    required_resource_access = optional(list(object({
      resource_app_id = string
      resource_access = list(object({
        id   = string
        type = string
      }))
    })))
    service_management_reference = optional(string)
    sign_in_audience             = optional(string)
    single_page_application = optional(object({
      redirect_uris = list(string)
    }))
    support_url          = optional(string)
    tags                 = optional(list(string))
    template_id          = optional(string)
    terms_of_service_url = optional(string)
    web = optional(object({
      redirect_uris = list(string)
      logout_url    = optional(string)
      homepage_url  = optional(string)
      implicit_grant = optional(object({
        access_token_issuance_enabled = bool
        id_token_issuance_enabled     = bool

      }))
    }))
    api = optional(object({
      known_client_applications = list(string)
      mapped_claims_enabled     = optional(bool, false)
      oauth2_permission_scope = optional(list(object({
        admin_consent_description  = string
        admin_consent_display_name = string
        id                         = string
        type                       = optional(string, "User")
        user_consent_description   = optional(string)
        user_consent_display_name  = optional(string)
        value                      = optional(string)
        enabled                    = optional(bool, true)
      })))
      requested_access_token_version = optional(number, 1)
    }))
    app_role = optional(list(object({
      allowed_member_types = list(string)
      description          = string
      display_name         = string
      id                   = string
      value                = optional(string)
      enabled              = optional(bool, true)
    })))
    feature_tags = optional(object({
      custom_single_sign_on = optional(bool, false)
      enterprise            = optional(bool, false)
      gallery               = optional(bool, false)
      hide                  = optional(bool, false)
    }))
    optional_claims = optional(object({
      access_token = list(object({
        name                  = string
        essential             = optional(bool)
        additional_properties = optional(list(string))
        source                = optional(string)
      }))
      id_token = list(object({
        name                  = string
        essential             = optional(bool)
        additional_properties = optional(list(string))
        source                = optional(string)
      }))
      saml2_token = list(object({
        name                  = string
        essential             = optional(bool)
        additional_properties = optional(list(string))
        source                = optional(string)
      }))
    }))
  }))
}
