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
