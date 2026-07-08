<!--
  Header for the minimal example README. Edit this file, then run `just docs`
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

# Minimal example

The smallest valid call to this module: required inputs only. The environment comes from the
Terraform workspace (`terraform.workspace`), not a variable. Run it with `just e2e minimal`, which
applies the stack then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
# Minimal call: one application registration, its service principal, and a single client secret.
# This is the smallest useful "give me an SPN I can authenticate with" shape. Any principal with
# Application.ReadWrite can apply it: no admin consent, no directory roles, no elevated Graph
# permissions are involved.
module "service_principal" {
  source = "../../"

  service_principals = {
    "sp-${var.short}-${var.loc}-${terraform.workspace}-min" = {
      description = "Minimal example service principal."

      client_secrets = {
        # No expiry set, so Azure assigns its default lifetime. The generated value is exported
        # (sensitive) for the caller to store. Pin start_date/end_date to control the window.
        default = {}
      }
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >= 3.0.0, < 4.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_service_principal"></a> [service\_principal](#module\_service\_principal) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_loc"></a> [loc](#input\_loc) | Outfix: short Azure region code used in resource names (for example uks). | `string` | `"uks"` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | Map of short region codes to Azure region slugs. | `map(string)` | <pre>{<br/>  "eus": "eastus",<br/>  "euw": "westeurope",<br/>  "uks": "uksouth",<br/>  "ukw": "ukwest"<br/>}</pre> | no |
| <a name="input_short"></a> [short](#input\_short) | Infix: short product code used in resource names. | `string` | `"ldo"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_client_ids"></a> [client\_ids](#output\_client\_ids) | Application client ids, keyed by service principal name. |
| <a name="output_client_secret_values"></a> [client\_secret\_values](#output\_client\_secret\_values) | Generated client secret values, keyed by "<spn>\|<secret>". |
| <a name="output_service_principal_object_ids"></a> [service\_principal\_object\_ids](#output\_service\_principal\_object\_ids) | Service principal object ids, keyed by service principal name. |
<!-- END_TF_DOCS -->
