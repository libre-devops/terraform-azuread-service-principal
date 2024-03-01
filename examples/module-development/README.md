```hcl
module "azuread_applications" {
  source = "../../"

  spns = [
    {
      spn_name                       = "ExampleSPN2"
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

      create_corresponding_enterprise_app = true
      create_client_secret                = true
      create_federated_credential         = true
      federated_credential_display_name   = "test"
      federated_credential_description    = "test2"
      federated_credential_audiences      = ["api://AzureADTokenExchange"]
      federated_credential_issuer         = "https://vstoken.dev.azure.com/4a23d149-8cee-4643-a57b-3b3db30e54ce"
      federated_credential_subject        = "sc://libredevops/libredevops/svp-lbd-uks-prd-mgmt-01"
    }
  ]
}
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.91.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azuread_applications"></a> [azuread\_applications](#module\_azuread\_applications) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [random_string.entropy](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [azurerm_client_config.current_creds](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_key_vault.mgmt_kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_resource_group.mgmt_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_ssh_public_key.mgmt_ssh_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/ssh_public_key) | data source |
| [azurerm_user_assigned_identity.mgmt_user_assigned_id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/user_assigned_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_Regions"></a> [Regions](#input\_Regions) | Converts shorthand name to longhand name via lookup on map list | `map(string)` | <pre>{<br>  "eus": "East US",<br>  "euw": "West Europe",<br>  "uks": "UK South",<br>  "ukw": "UK West"<br>}</pre> | no |
| <a name="input_env"></a> [env](#input\_env) | This is passed as an environment variable, it is for the shorthand environment tag for resource.  For example, production = prod | `string` | `"prd"` | no |
| <a name="input_loc"></a> [loc](#input\_loc) | The shorthand name of the Azure location, for example, for UK South, use uks.  For UK West, use ukw. Normally passed as TF\_VAR in pipeline | `string` | `"uks"` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of this resource | `string` | `"tst"` | no |
| <a name="input_short"></a> [short](#input\_short) | This is passed as an environment variable, it is for a shorthand name for the environment, for example hello-world = hw | `string` | `"lbd"` | no |

## Outputs

No outputs.
