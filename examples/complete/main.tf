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
