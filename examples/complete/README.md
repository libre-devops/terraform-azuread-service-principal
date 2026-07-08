<!--
  Header for the complete example README. Edit this file, then run `just docs`
  (or ./Sort-LdoTerraform.ps1 -IncludeExamples) to regenerate the section between the markers.
  The example's main.tf is embedded into the README automatically (see .terraform-docs.yml).
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="200">
    </picture>
  </a>
</div>

# Complete example

Exercises the fuller surface of this module by composing two calls: a **client application**
(redirect URIs, optional claims, a GitHub federated credential, two client secrets, and a
requested delegated Graph scope) and a **resource API application** (a published app role and two
permission scopes, an `api://{clientId}` identifier URI, a client certificate, and the client app
registered as a known and pre-authorized client). The resource API also requests a Graph
application permission.

Admin consent for the Graph permissions is left off (`grant_admin_consent = false`) because
granting it needs elevated Graph permissions; the permissions are requested but not consented. The
flexible federated identity credential is a preview feature and is likewise gated off
(`enable_flexible_federated_credentials = false`). The environment comes from the Terraform
workspace (`terraform.workspace`), not a variable. Run it with `just e2e complete`, which applies
the stack then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
locals {
  prefix = "sp-${var.short}-${var.loc}-${terraform.workspace}-cmp"

  # Permission scope ids are pinned so the resource API can pre-authorize the client app for the
  # exact scopes (pre_authorized.permission_ids must reference ids that exist on the API app, and a
  # module cannot reference its own outputs from its own inputs).
  scope_read_id  = "11111111-1111-1111-1111-111111111111"
  scope_write_id = "22222222-2222-2222-2222-222222222222"
}

data "azuread_client_config" "current" {}

# A self-signed certificate to exercise the client-certificate credential path. Generated locally
# by the tls provider, so no cloud calls and nothing to clean up.
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "example" {
  private_key_pem = tls_private_key.example.private_key_pem

  subject {
    common_name = local.prefix
  }

  validity_period_hours = 8760
  allowed_uses          = ["digital_signature", "key_encipherment"]
}

# ---------------------------------------------------------------------------------------------------
# Client application: redirect URIs, federated credentials, and requested (delegated) Graph access.
# No dependencies, so it is created first and its client id feeds the resource API below.
# ---------------------------------------------------------------------------------------------------
module "client_app" {
  source = "../../"

  service_principals = {
    "${local.prefix}-client" = {
      description                        = "Complete example client application."
      sign_in_audience                   = "AzureADMyOrg"
      group_membership_claims            = ["SecurityGroup"]
      homepage_url                       = "https://app.example.com/"
      logout_url                         = "https://app.example.com/logout"
      marketing_url                      = "https://example.com/"
      privacy_statement_url              = "https://example.com/privacy"
      support_url                        = "https://support.example.com/"
      terms_of_service_url               = "https://example.com/terms"
      implicit_id_token_issuance_enabled = true

      owners = [data.azuread_client_config.current.object_id]

      redirect_uris = {
        Web          = ["https://app.example.com/callback", "https://app.example.com/signin-oidc"]
        SPA          = ["https://app.example.com/spa"]
        PublicClient = ["https://login.microsoftonline.com/common/oauth2/nativeclient"]
      }

      optional_claims = {
        id_token = [{
          name                  = "upn"
          essential             = true
          additional_properties = ["include_externally_authenticated_upn"]
        }]
        access_token = [{ name = "groups" }]
      }

      # Requested (not consented unless grant_admin_consent = true): a delegated Graph scope.
      microsoft_graph_delegated_scopes    = ["User.Read"]
      microsoft_graph_grant_admin_consent = var.grant_admin_consent

      client_secrets = {
        primary   = { display_name = "primary" }
        secondary = { display_name = "secondary" }
      }

      federated_credentials = {
        github-main = {
          display_name = "github-main"
          issuer       = "https://token.actions.githubusercontent.com"
          subject      = "repo:libre-devops/terraform-azuread-service-principal:ref:refs/heads/main"
          audiences    = ["api://AzureADTokenExchange"]
          description  = "GitHub Actions, main branch."
        }
      }

      # Flexible federated credentials are a Microsoft Entra preview; gated off by default so the
      # live self-test never depends on a preview feature. Flip enable_flexible_federated_credentials
      # in a tenant that has the preview enabled to prove it.
      flexible_federated_credentials = var.enable_flexible_federated_credentials ? {
        github-flex = {
          display_name               = "github-flex"
          issuer                     = "https://token.actions.githubusercontent.com"
          audience                   = "api://AzureADTokenExchange"
          claims_matching_expression = "claims['sub'] matches 'repo:libre-devops/terraform-azuread-service-principal:ref:refs/heads/*'"
          description                = "GitHub Actions, any branch."
        }
      } : {}
    }
  }
}

# ---------------------------------------------------------------------------------------------------
# Resource API application: publishes app roles and scopes, exposes an identifier URI, knows and
# pre-authorizes the client app, carries a client certificate, and requests (not consents to) a
# Graph application permission.
# ---------------------------------------------------------------------------------------------------
module "api_app" {
  source = "../../"

  service_principals = {
    "${local.prefix}-api" = {
      description     = "Complete example resource API application."
      account_enabled = true

      owners                   = [data.azuread_client_config.current.object_id]
      service_principal_owners = [data.azuread_client_config.current.object_id]
      default_identifier_uri   = true

      app_roles = {
        admin = {
          allowed_member_types = ["Application", "User"]
          display_name         = "Administrator"
          description          = "Administer the resource API."
          value                = "Admin.All"
        }
      }

      permission_scopes = {
        read = {
          scope_id                   = local.scope_read_id
          value                      = "Data.Read"
          admin_consent_display_name = "Read data"
          admin_consent_description  = "Allow the application to read data."
          type                       = "User"
        }
        write = {
          scope_id                   = local.scope_write_id
          value                      = "Data.Write"
          admin_consent_display_name = "Write data"
          admin_consent_description  = "Allow the application to write data."
          type                       = "Admin"
        }
      }

      # Link the client app: it is a known client, and it is pre-authorized for the read scope
      # (no user consent prompt). Both reference the client app created above.
      known_client_ids = [module.client_app.client_ids["${local.prefix}-client"]]

      pre_authorized_applications = {
        client = {
          authorized_client_id = module.client_app.client_ids["${local.prefix}-client"]
          permission_ids       = [local.scope_read_id]
        }
      }

      client_certificates = {
        primary = {
          type     = "AsymmetricX509Cert"
          encoding = "pem"
          value    = tls_self_signed_cert.example.cert_pem
          end_date = tls_self_signed_cert.example.validity_end_time
        }
      }

      # Requested (not consented unless grant_admin_consent = true): a Graph application permission.
      microsoft_graph_application_roles   = ["User.Read.All"]
      microsoft_graph_grant_admin_consent = var.grant_admin_consent

      service_principal_tags = ["example", "resource-api"]
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >= 3.0.0, < 4.0.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | >= 3.0.0, < 4.0.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0.0, < 5.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_api_app"></a> [api\_app](#module\_api\_app) | ../../ | n/a |
| <a name="module_client_app"></a> [client\_app](#module\_client\_app) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [tls_private_key.example](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.example](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_flexible_federated_credentials"></a> [enable\_flexible\_federated\_credentials](#input\_enable\_flexible\_federated\_credentials) | Whether to create the flexible federated identity credential. Off by default because it is a<br/>Microsoft Entra preview feature and the live self-test should not depend on a preview toggle. | `bool` | `false` | no |
| <a name="input_grant_admin_consent"></a> [grant\_admin\_consent](#input\_grant\_admin\_consent) | Whether to actually grant tenant-wide admin consent for the requested Microsoft Graph<br/>permissions (app role assignments and delegated grants). Left false by default: granting<br/>consent needs elevated Graph permissions (AppRoleAssignment.ReadWrite.All,<br/>Directory.ReadWrite.All) that a plain Application.ReadWrite CI principal does not hold, so the<br/>self-test requests the permissions without consenting. Set true when running as a principal<br/>that can consent. | `bool` | `false` | no |
| <a name="input_loc"></a> [loc](#input\_loc) | Outfix: short Azure region code used in resource names (for example uks). | `string` | `"uks"` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | Map of short region codes to Azure region slugs. | `map(string)` | <pre>{<br/>  "eus": "eastus",<br/>  "euw": "westeurope",<br/>  "uks": "uksouth",<br/>  "ukw": "ukwest"<br/>}</pre> | no |
| <a name="input_short"></a> [short](#input\_short) | Infix: short product code used in resource names. | `string` | `"ldo"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_app_client_ids"></a> [api\_app\_client\_ids](#output\_api\_app\_client\_ids) | Resource API application client ids. |
| <a name="output_api_app_published_app_role_ids"></a> [api\_app\_published\_app\_role\_ids](#output\_api\_app\_published\_app\_role\_ids) | Resolved app role ids published by the resource API, keyed by role name. |
| <a name="output_api_app_published_scope_ids"></a> [api\_app\_published\_scope\_ids](#output\_api\_app\_published\_scope\_ids) | Resolved permission scope ids published by the resource API, keyed by scope name. |
| <a name="output_client_app_client_ids"></a> [client\_app\_client\_ids](#output\_client\_app\_client\_ids) | Client application client ids. |
| <a name="output_client_app_secret_values"></a> [client\_app\_secret\_values](#output\_client\_app\_secret\_values) | Generated client secret values for the client application. |
| <a name="output_client_app_service_principal_object_ids"></a> [client\_app\_service\_principal\_object\_ids](#output\_client\_app\_service\_principal\_object\_ids) | Client application service principal object ids. |
<!-- END_TF_DOCS -->
