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
