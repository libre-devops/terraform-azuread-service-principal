module "azuread_applications" {
  source = "../../"

  spns = [
    {
      spn_name                       = "ExampleSPN1"
      identifier_uris                = ["http://example.com/spn1"]
      description                    = "Example Description for SPN1"
      device_only_auth_enabled       = false
      fallback_public_client_enabled = true
      group_membership_claims        = ["None"]
      marketing_url                  = "http://example.com/marketing1"
      notes                          = "Example notes for SPN1"
      oauth2_post_response_required  = false
      prevent_duplicate_names        = true
      privacy_statement_url          = "http://example.com/privacy1"
      required_resource_access = [
        {
          resource_app_id = "00000003-0000-0000-c000-000000000000" # Example Microsoft Graph
          resource_access = [
            {
              id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
              type = "Scope"
            }
          ]
        }
      ]
      service_management_reference = "ExampleServiceManagementReference1"
      sign_in_audience             = "AzureADMyOrg"
      support_url                  = "http://example.com/support1"
      tags                         = ["example", "spn1"]
      template_id                  = null
      terms_of_service_url         = "http://example.com/tos1"
      web = {
        redirect_uris = ["http://example.com/auth1"]
        logout_url    = "http://example.com/logout1"
        homepage_url  = "http://example.com/home1"
        implicit_grant = {
          access_token_issuance_enabled = true
          id_token_issuance_enabled     = true
        }
      }
      api = {
        known_client_applications = ["1fec8e78-bce4-4aaf-ab1b-5451cc387264"] # Example Client App ID
        mapped_claims_enabled     = false
        oauth2_permission_scopes = [
          {
            admin_consent_description  = "Allow the application to access ExampleSPN1 on behalf of the signed-in user."
            admin_consent_display_name = "Access ExampleSPN1"
            id                         = "00000000-0000-0000-0000-000000000000" # Example ID
            type                       = "User"
            user_consent_description   = "Allow the application to access ExampleSPN1 on your behalf."
            user_consent_display_name  = "Access ExampleSPN1"
            value                      = "example.access"
            enabled                    = true
          }
        ]
        requested_access_token_version = 2
      }
      optional_claims = {
        access_token = [
          {
            name                  = "email"
            essential             = true
            additional_properties = ["emit_as_roles"]
            source                = null
          }
        ]
        id_token    = []
        saml2_token = []
      }
    }
    # You can add more SPN configurations here
  ]
}
