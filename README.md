<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure AD Service Principal

Create Microsoft Entra (Azure AD) applications and service principals, and configure the whole
surface around them: client secrets, certificates, federated and flexible federated credentials,
owners, redirect URIs, published app roles and OAuth2 scopes, requested API permissions, and
tenant-wide admin consent (with a one-line Microsoft Graph shortcut).

[![CI](https://github.com/libre-devops/terraform-azuread-service-principal/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azuread-service-principal/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azuread-service-principal?sort=semver&label=release)](https://github.com/libre-devops/terraform-azuread-service-principal/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azuread-service-principal)](./LICENSE)

---

## Usage

```hcl
module "service_principal" {
  source  = "libre-devops/service-principal/azuread"
  version = "~> 4.0"

  service_principals = {
    "sp-ldo-uks-dev-app" = {
      description = "Workload identity for the app."

      # One client secret (Azure assigns a default expiry when none is given).
      client_secrets = { default = {} }

      # Request Microsoft Graph permissions by name and grant tenant-wide admin consent in one shot.
      microsoft_graph_application_roles = ["User.Read.All"]
      microsoft_graph_delegated_scopes  = ["User.Read"]
    }
  }
}
```

## Design

The base object is `azuread_application_registration` composed with the granular sub-resources
(`azuread_application_api_access`, `_app_role`, `_permission_scope`, `_owner`, `_redirect_uris`,
`_identifier_uri`, `_fallback_public_client`, `_known_clients`, `_optional_claims`,
`_pre_authorized`), rather than the monolithic `azuread_application`. That is the drift-resistant,
composable path and the only one compatible with the owner and redirect-URI resources. As a
result a few application-only knobs are intentionally not exposed (`device_only_auth_enabled`,
`logo_image`, `oauth2_post_response_required`, `prevent_duplicate_names`, application `tags`, and
the gallery `template_id`).

## Required permissions

The principal running Terraform needs Microsoft Graph `Application.ReadWrite.All` (or
`Application.ReadWrite.OwnedBy`) to manage applications and service principals. Granting admin
consent additionally needs `AppRoleAssignment.ReadWrite.All` (application permissions) and
`Directory.ReadWrite.All` (delegated grants), which is why the complete example leaves
`grant_admin_consent` off by default. See also the companion
[terraform-azuread-role-assignment](https://github.com/libre-devops/terraform-azuread-role-assignment)
module for Entra directory roles.

## Examples

- [`examples/minimal`](./examples/minimal) - the smallest valid call: one application, its service principal, and a client secret.
- [`examples/complete`](./examples/complete) - the fuller surface: a client app and a resource-API app composed together, with roles, scopes, federated credentials, a certificate, and the Graph shortcut.

## Developing

Local work needs **PowerShell 7+** and **[`just`](https://github.com/casey/just)**, because the recipes
wrap the [LibreDevOpsHelpers](https://www.powershellgallery.com/packages/LibreDevOpsHelpers)
PowerShell module (the same engine the `libre-devops/terraform-azure` action runs in CI). Install
just with `brew install just`, or `uv tool add rust-just` then `uv run just <recipe>`.

Run `just` to list recipes: `just update-ldo-pwsh` (install or force-update LibreDevOpsHelpers from
PSGallery), `just validate`, `just scan` (Trivy only), `just pwsh-analyze` (PSScriptAnalyzer only),
`just plan`, `just apply`, `just destroy`, `just e2e`, `just test`, and `just docs` (the
plan/apply/destroy recipes mirror the action, including the storage firewall dance; `just e2e`
applies an example then always destroys it, defaulting to `minimal`, so nothing is left running).
Releasing is also `just`:
`just increment-release [patch|minor|major]` bumps, tags, and publishes a GitHub release, and the
Terraform Registry picks up the tag.

## Security scan exceptions

This module is scanned with [Trivy](https://github.com/aquasecurity/trivy); HIGH and CRITICAL
findings fail the build. Any waiver is a deliberate, reviewed decision, never a way to quiet a
finding that should be fixed. Waivers live in [`.trivyignore.yaml`](./.trivyignore.yaml) (the
machine-applied source of truth, passed to Trivy with `--ignorefile`) and are mirrored in the table
below so the reason is auditable.

| Trivy ID | Resource | Finding | Justification |
|----------|----------|---------|---------------|
| _None_   |          |         |               |

To add an exception: add an entry to `.trivyignore.yaml` (`id`, optional `paths` to scope it, and a
`statement` recording why), then add a matching row here. Where the finding is out of this module's
scope, point the justification at the Libre DevOps module that does address it (for example the
private-endpoint module). Both the file and this table are reviewed in the pull request.

## Reference

The Requirements, Providers, Inputs, Outputs, and Resources below are generated by `terraform-docs`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >= 3.0.0, < 4.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.0, < 4.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.0, < 1.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | >= 3.0.0, < 4.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.0, < 4.0.0 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.9.0, < 1.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_app_role_assignment.graph](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_app_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/app_role_assignment) | resource |
| [azuread_application_api_access.graph](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_api_access) | resource |
| [azuread_application_api_access.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_api_access) | resource |
| [azuread_application_app_role.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_app_role) | resource |
| [azuread_application_certificate.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_certificate) | resource |
| [azuread_application_fallback_public_client.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_fallback_public_client) | resource |
| [azuread_application_federated_identity_credential.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_federated_identity_credential) | resource |
| [azuread_application_flexible_federated_identity_credential.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_flexible_federated_identity_credential) | resource |
| [azuread_application_identifier_uri.default](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_identifier_uri) | resource |
| [azuread_application_identifier_uri.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_identifier_uri) | resource |
| [azuread_application_known_clients.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_known_clients) | resource |
| [azuread_application_optional_claims.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_optional_claims) | resource |
| [azuread_application_owner.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_owner) | resource |
| [azuread_application_password.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_application_permission_scope.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_permission_scope) | resource |
| [azuread_application_pre_authorized.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_pre_authorized) | resource |
| [azuread_application_redirect_uris.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_redirect_uris) | resource |
| [azuread_application_registration.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_registration) | resource |
| [azuread_service_principal.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal_delegated_permission_grant.graph](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal_delegated_permission_grant) | resource |
| [azuread_service_principal_delegated_permission_grant.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal_delegated_permission_grant) | resource |
| [random_uuid.app_role](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [random_uuid.permission_scope](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) | resource |
| [time_static.client_certificate](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static) | resource |
| [time_static.client_secret](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static) | resource |
| [azuread_application_published_app_ids.well_known](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/application_published_app_ids) | data source |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [azuread_service_principal.msgraph](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_service_principals"></a> [service\_principals](#input\_service\_principals) | Map of service principals to create, keyed by a stable logical name (the key is used as the<br/>default application display name and to build the flattened keys of every child resource, so<br/>keep it unique and meaningful). Each entry drives an application registration<br/>(azuread\_application\_registration) plus, optionally, a service principal and the full set of<br/>credentials, published roles/scopes, requested API permissions, owners and admin consent.<br/><br/>The map(object) shape keeps callers declarative: name a service principal once and hang all of<br/>its configuration off that key. Everything except display\_name is optional so the smallest call<br/>is a single key with an empty object. | <pre>map(object({<br/>    # ---- Application registration core (azuread_application_registration) ----<br/>    display_name                           = optional(string)<br/>    description                            = optional(string)<br/>    sign_in_audience                       = optional(string, "AzureADMyOrg")<br/>    group_membership_claims                = optional(list(string))<br/>    homepage_url                           = optional(string)<br/>    logout_url                             = optional(string)<br/>    marketing_url                          = optional(string)<br/>    notes                                  = optional(string)<br/>    privacy_statement_url                  = optional(string)<br/>    support_url                            = optional(string)<br/>    terms_of_service_url                   = optional(string)<br/>    service_management_reference           = optional(string)<br/>    requested_access_token_version         = optional(number, 2)<br/>    implicit_access_token_issuance_enabled = optional(bool)<br/>    implicit_id_token_issuance_enabled     = optional(bool)<br/><br/>    # ---- Fallback public client (azuread_application_fallback_public_client) ----<br/>    # Leave null to let Azure decide (recommended). Set true/false to pin it.<br/>    fallback_public_client_enabled = optional(bool)<br/><br/>    # ---- Identifier URIs (azuread_application_identifier_uri, one resource per URI) ----<br/>    # Custom identifier URIs must sit on a verified publisher domain (or be the api://{clientId}<br/>    # form). Set default_identifier_uri to have the module mint api://{client_id} for you, which<br/>    # Azure always accepts because the application inherently owns its own client id.<br/>    identifier_uris        = optional(set(string), [])<br/>    default_identifier_uri = optional(bool, false)<br/><br/>    # ---- Redirect URIs (azuread_application_redirect_uris, one resource per type) ----<br/>    # Keyed by URI type: "Web", "SPA" or "PublicClient".<br/>    redirect_uris = optional(map(set(string)), {})<br/><br/>    # ---- Known client applications (azuread_application_known_clients) ----<br/>    known_client_ids = optional(set(string), [])<br/><br/>    # ---- Owners of the application registration (azuread_application_owner, one per) ----<br/>    owners = optional(set(string), [])<br/><br/>    # ---- Optional claims (azuread_application_optional_claims) ----<br/>    optional_claims = optional(object({<br/>      access_token = optional(list(object({<br/>        name                  = string<br/>        source                = optional(string)<br/>        essential             = optional(bool)<br/>        additional_properties = optional(list(string))<br/>      })), [])<br/>      id_token = optional(list(object({<br/>        name                  = string<br/>        source                = optional(string)<br/>        essential             = optional(bool)<br/>        additional_properties = optional(list(string))<br/>      })), [])<br/>      saml2_token = optional(list(object({<br/>        name                  = string<br/>        source                = optional(string)<br/>        essential             = optional(bool)<br/>        additional_properties = optional(list(string))<br/>      })), [])<br/>    }))<br/><br/>    # ---- App roles this application PUBLISHES (azuread_application_app_role) ----<br/>    # Keyed by a logical name. role_id is optional: when omitted a stable random UUID is generated<br/>    # and kept in state, so callers declare roles by intent, not by hand-minted GUIDs.<br/>    app_roles = optional(map(object({<br/>      allowed_member_types = list(string)<br/>      description          = string<br/>      display_name         = string<br/>      value                = optional(string)<br/>      role_id              = optional(string)<br/>    })), {})<br/><br/>    # ---- OAuth2 permission scopes this application PUBLISHES (azuread_application_permission_scope) ----<br/>    permission_scopes = optional(map(object({<br/>      admin_consent_description  = string<br/>      admin_consent_display_name = string<br/>      value                      = string<br/>      type                       = optional(string, "User")<br/>      user_consent_description   = optional(string)<br/>      user_consent_display_name  = optional(string)<br/>      scope_id                   = optional(string)<br/>    })), {})<br/><br/>    # ---- Pre-authorized client applications (azuread_application_pre_authorized) ----<br/>    pre_authorized_applications = optional(map(object({<br/>      authorized_client_id = string<br/>      permission_ids       = list(string)<br/>    })), {})<br/><br/>    # ---- API permissions this application REQUESTS, per resource API (azuread_application_api_access) ----<br/>    # Keyed by a logical name. api_client_id is the resource API's client id (for Microsoft Graph<br/>    # prefer the microsoft_graph_* shortcuts below). At least one of role_ids/scope_ids per entry.<br/>    api_permissions = optional(map(object({<br/>      api_client_id = string<br/>      role_ids      = optional(set(string), [])<br/>      scope_ids     = optional(set(string), [])<br/>    })), {})<br/><br/>    # ---- Microsoft Graph shortcut ----<br/>    # Declare Graph permissions by their published NAME (for example "User.Read.All"). The module<br/>    # resolves the ids against the tenant's Microsoft Graph service principal, requests them on the<br/>    # application, and (when microsoft_graph_grant_admin_consent is true and a service principal is<br/>    # created) grants tenant-wide admin consent: application roles via azuread_app_role_assignment,<br/>    # delegated scopes via azuread_service_principal_delegated_permission_grant.<br/>    microsoft_graph_application_roles   = optional(set(string), [])<br/>    microsoft_graph_delegated_scopes    = optional(set(string), [])<br/>    microsoft_graph_grant_admin_consent = optional(bool, true)<br/><br/>    # ---- Generic admin consent escape hatches (any resource API) ----<br/>    # Grant an app role (application permission) held by any resource service principal TO this<br/>    # service principal (azuread_app_role_assignment). Use for non-Graph APIs, or the Graph<br/>    # default role id 00000000-0000-0000-0000-000000000000.<br/>    app_role_assignments = optional(map(object({<br/>      resource_object_id = string<br/>      app_role_id        = string<br/>    })), {})<br/><br/>    # Grant delegated permissions (azuread_service_principal_delegated_permission_grant). Omit<br/>    # user_object_id to consent for all users (admin consent).<br/>    delegated_permission_grants = optional(map(object({<br/>      resource_service_principal_object_id = string<br/>      claim_values                         = set(string)<br/>      user_object_id                       = optional(string)<br/>    })), {})<br/><br/>    # ---- Service principal (azuread_service_principal) ----<br/>    create_service_principal        = optional(bool, true)<br/>    account_enabled                 = optional(bool, true)<br/>    app_role_assignment_required    = optional(bool, false)<br/>    service_principal_description   = optional(string)<br/>    service_principal_owners        = optional(set(string), [])<br/>    alternative_names               = optional(set(string))<br/>    login_url                       = optional(string)<br/>    service_principal_notes         = optional(string)<br/>    notification_email_addresses    = optional(set(string))<br/>    preferred_single_sign_on_mode   = optional(string)<br/>    saml_single_sign_on_relay_state = optional(string)<br/>    service_principal_tags          = optional(set(string))<br/>    use_existing                    = optional(bool)<br/>    feature_tags = optional(object({<br/>      custom_single_sign_on = optional(bool, false)<br/>      enterprise            = optional(bool, false)<br/>      gallery               = optional(bool, false)<br/>      hide                  = optional(bool, false)<br/>    }))<br/><br/>    # ---- Client secrets (azuread_application_password, one per key) ----<br/>    # end_date_relative (a duration such as "2160h") is turned into end_date here, from start_date<br/>    # or the moment the credential was first planned (a time_static anchor, re-taken when<br/>    # rotate_when_changed changes): azuread 3.x ignores end_date_relative for passwords, which<br/>    # left every secret on Graph's default lifetime.<br/>    client_secrets = optional(map(object({<br/>      display_name        = optional(string)<br/>      start_date          = optional(string)<br/>      end_date            = optional(string)<br/>      end_date_relative   = optional(string)<br/>      rotate_when_changed = optional(map(string))<br/>    })), {})<br/><br/>    # ---- Client certificates (azuread_application_certificate, one per key) ----<br/>    # end_date_relative is turned into end_date the same way (the anchor is re-taken when the<br/>    # certificate changes): azuread 3.x errors on end_date_relative alongside start_date.<br/>    client_certificates = optional(map(object({<br/>      value             = string<br/>      type              = optional(string, "AsymmetricX509Cert")<br/>      encoding          = optional(string, "pem")<br/>      start_date        = optional(string)<br/>      end_date          = optional(string)<br/>      end_date_relative = optional(string)<br/>      key_id            = optional(string)<br/>    })), {})<br/><br/>    # ---- Federated identity credentials (azuread_application_federated_identity_credential) ----<br/>    federated_credentials = optional(map(object({<br/>      display_name = string<br/>      issuer       = string<br/>      subject      = string<br/>      audiences    = optional(set(string), ["api://AzureADTokenExchange"])<br/>      description  = optional(string)<br/>    })), {})<br/><br/>    # ---- Flexible federated identity credentials (azuread_application_flexible_federated_identity_credential) ----<br/>    flexible_federated_credentials = optional(map(object({<br/>      display_name               = string<br/>      issuer                     = string<br/>      claims_matching_expression = string<br/>      audience                   = optional(string, "api://AzureADTokenExchange")<br/>      description                = optional(string)<br/>    })), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_ids"></a> [application\_ids](#output\_application\_ids) | Map of service principal key to the application registration resource id (the /applications/{objectId} form used as application\_id by child resources). |
| <a name="output_application_ids_zipmap"></a> [application\_ids\_zipmap](#output\_application\_ids\_zipmap) | Map of service principal key to an object of its name and application id, for easy composition (matches the estate zipmap convention). |
| <a name="output_application_object_ids"></a> [application\_object\_ids](#output\_application\_object\_ids) | Map of service principal key to the application object id. |
| <a name="output_applications"></a> [applications](#output\_applications) | Map of service principal key to the full set of useful application registration attributes. |
| <a name="output_client_certificate_key_ids"></a> [client\_certificate\_key\_ids](#output\_client\_certificate\_key\_ids) | Map of "<spn>\|<certificate>" key to the certificate key id. |
| <a name="output_client_ids"></a> [client\_ids](#output\_client\_ids) | Map of service principal key to the application client id (also called the application id / appId). |
| <a name="output_client_secret_values"></a> [client\_secret\_values](#output\_client\_secret\_values) | Map of "<spn>\|<secret>" key to just the generated secret value. |
| <a name="output_client_secrets"></a> [client\_secrets](#output\_client\_secrets) | Map of "<spn>\|<secret>" key to the secret key id, value and display name. Store these in a secret manager; they are only shown at creation. |
| <a name="output_federated_credential_ids"></a> [federated\_credential\_ids](#output\_federated\_credential\_ids) | Map of "<spn>\|<credential>" key to the federated identity credential id. |
| <a name="output_flexible_federated_credential_ids"></a> [flexible\_federated\_credential\_ids](#output\_flexible\_federated\_credential\_ids) | Map of "<spn>\|<credential>" key to the flexible federated identity credential id. |
| <a name="output_published_app_role_ids"></a> [published\_app\_role\_ids](#output\_published\_app\_role\_ids) | Map of service principal key to a map of app role logical name to its resolved role id. |
| <a name="output_published_permission_scope_ids"></a> [published\_permission\_scope\_ids](#output\_published\_permission\_scope\_ids) | Map of service principal key to a map of permission scope logical name to its resolved scope id. |
| <a name="output_service_principal_object_ids"></a> [service\_principal\_object\_ids](#output\_service\_principal\_object\_ids) | Map of service principal key to the service principal object id (the value to use in role assignments and group memberships). |
| <a name="output_service_principals"></a> [service\_principals](#output\_service\_principals) | Map of service principal key to the full set of useful service principal attributes. |
<!-- END_TF_DOCS -->
