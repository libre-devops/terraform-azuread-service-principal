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
