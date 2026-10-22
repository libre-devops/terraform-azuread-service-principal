# Plan-time tests for the module. The azuread, random and time providers are mocked, so no credentials
# and no cloud calls are needed:
#   terraform init -backend=false && terraform test
#
# The Microsoft Graph data sources are mocked with fixed maps so the graph shortcut resolves the
# same way it would against a real tenant.

mock_provider "azuread" {
  mock_data "azuread_application_published_app_ids" {
    defaults = {
      result = { MicrosoftGraph = "00000003-0000-0000-c000-000000000000" }
    }
  }

  mock_data "azuread_service_principal" {
    defaults = {
      object_id                   = "0a0a0a0a-0b0b-0c0c-0d0d-0e0e0e0e0e0e"
      app_role_ids                = { "User.Read.All" = "df021288-bdef-4463-88db-98f22de89214" }
      oauth2_permission_scope_ids = { "User.Read" = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" }
    }
  }
}

mock_provider "random" {}
mock_provider "time" {}

variables {
  service_principals = {
    api = {
      description = "API app"

      app_roles = {
        admin = {
          allowed_member_types = ["Application", "User"]
          display_name         = "Administrator"
          description          = "Administer"
          value                = "Admin.All"
        }
      }

      permission_scopes = {
        read = {
          value                      = "Data.Read"
          admin_consent_display_name = "Read data"
          admin_consent_description  = "Read data"
          type                       = "User"
        }
      }

      client_secrets        = { primary = { end_date = "2027-01-01T00:00:00Z" } }
      federated_credentials = { gh = { display_name = "gh", issuer = "https://token.actions.githubusercontent.com", subject = "repo:o/r:ref:refs/heads/main" } }

      microsoft_graph_application_roles = ["User.Read.All"]
      microsoft_graph_delegated_scopes  = ["User.Read"]
    }

    daemon = {
      app_role_assignments = {
        custom = {
          resource_object_id = "99999999-9999-9999-9999-999999999999"
          app_role_id        = "88888888-8888-8888-8888-888888888888"
        }
      }
    }

    noapp = {
      create_service_principal = false
    }
  }
}

run "application_registration_display_name_defaults_to_key" {
  command = plan

  assert {
    condition     = azuread_application_registration.this["api"].display_name == "api"
    error_message = "display_name should default to the map key when not supplied."
  }
}

run "service_principal_is_gated_by_flag" {
  command = plan

  assert {
    condition     = length(azuread_service_principal.this) == 2
    error_message = "A service principal should be created for api and daemon, but not for noapp (create_service_principal = false)."
  }
}

run "child_credentials_are_created" {
  command = plan

  assert {
    condition     = length(azuread_application_password.this) == 1
    error_message = "The api client secret should be created."
  }

  assert {
    condition     = length(azuread_application_federated_identity_credential.this) == 1
    error_message = "The api federated credential should be created."
  }
}

run "app_role_generates_uuid_when_unset" {
  command = plan

  assert {
    condition     = length(random_uuid.app_role) == 1 && length(random_uuid.permission_scope) == 1
    error_message = "A random UUID should be generated for app roles and permission scopes that do not pin an id."
  }
}

run "graph_shortcut_requests_permissions" {
  command = plan

  assert {
    condition     = contains(azuread_application_api_access.graph["api"].role_ids, "df021288-bdef-4463-88db-98f22de89214")
    error_message = "The requested Graph application role id should be resolved onto the api_access request."
  }

  assert {
    condition     = contains(azuread_application_api_access.graph["api"].scope_ids, "e1fe6dd8-ba31-4d61-89e7-88639da4683d")
    error_message = "The requested Graph delegated scope id should be resolved onto the api_access request."
  }
}

run "graph_shortcut_grants_admin_consent_by_default" {
  command = plan

  assert {
    condition     = azuread_app_role_assignment.graph["api|User.Read.All"].app_role_id == "df021288-bdef-4463-88db-98f22de89214"
    error_message = "By default the Graph application permission should be granted admin consent via an app role assignment."
  }

  assert {
    condition     = length(azuread_service_principal_delegated_permission_grant.graph) == 1
    error_message = "By default the Graph delegated scopes should be granted admin consent via a delegated permission grant."
  }
}

run "generic_app_role_assignment_escape_hatch" {
  command = plan

  assert {
    condition     = azuread_app_role_assignment.this["daemon|custom"].app_role_id == "88888888-8888-8888-8888-888888888888"
    error_message = "The generic app_role_assignments escape hatch should create an assignment with the given app role id."
  }
}

run "invalid_sign_in_audience_is_rejected" {
  command = plan

  variables {
    service_principals = {
      bad = { sign_in_audience = "NotARealAudience" }
    }
  }

  expect_failures = [var.service_principals]
}

run "feature_tags_and_tags_are_mutually_exclusive" {
  command = plan

  variables {
    service_principals = {
      bad = {
        service_principal_tags = ["a"]
        feature_tags           = { enterprise = true }
      }
    }
  }

  expect_failures = [var.service_principals]
}

# end_date_relative becomes an end_date from a fixed anchor (or start_date), and is never passed to
# the provider: azuread 3.x ignores it for passwords and errors on it for a certificate with a
# start_date.
run "relative_end_dates_are_resolved_from_a_fixed_anchor" {
  command = plan

  variables {
    service_principals = {
      caller = {
        client_secrets = {
          rotating = { end_date_relative = "2160h", rotate_when_changed = { round = "1" } }
          fixed    = { end_date = "2027-01-01T00:00:00Z" }
        }
        client_certificates = {
          dated = { value = "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----", start_date = "2026-11-01T00:00:00Z", end_date_relative = "720h" }
        }
      }
    }
  }

  override_resource {
    target          = time_static.client_secret
    override_during = plan
    values          = { rfc3339 = "2026-10-22T00:00:00Z" }
  }

  override_resource {
    target          = time_static.client_certificate
    override_during = plan
    values          = { rfc3339 = "2026-10-22T00:00:00Z" }
  }

  assert {
    condition = (
      azuread_application_password.this["caller|rotating"].end_date == "2027-01-20T00:00:00Z" &&
      azuread_application_password.this["caller|rotating"].end_date_relative == null
    )
    error_message = "A 90 day secret ends 90 days after its anchor, set as end_date."
  }

  assert {
    condition     = azuread_application_password.this["caller|fixed"].end_date == "2027-01-01T00:00:00Z" && !contains(keys(time_static.client_secret), "caller|fixed")
    error_message = "An explicit end_date passes through, with no anchor."
  }

  assert {
    condition = (
      azuread_application_certificate.this["caller|dated"].end_date == "2026-12-01T00:00:00Z" &&
      azuread_application_certificate.this["caller|dated"].end_date_relative == null
    )
    error_message = "A certificate with a start_date ends end_date_relative after it."
  }

  assert {
    condition     = time_static.client_secret["caller|rotating"].triggers["round"] == "1"
    error_message = "The anchor is re-taken when rotate_when_changed changes."
  }
}

run "an_end_date_and_a_relative_end_date_conflict" {
  command = plan

  variables {
    service_principals = {
      caller = {
        client_secrets = { both = { end_date = "2027-01-01T00:00:00Z", end_date_relative = "2160h" } }
      }
    }
  }

  expect_failures = [var.service_principals]
}
