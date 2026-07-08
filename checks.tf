# check blocks run after every plan and apply and emit a warning (without blocking) when an
# invariant is violated. They surface the Azure AD footguns this module cannot express in the
# type system without making the common case harder.

# In Azure AD, an application's app roles and OAuth2 permission scopes share one namespace: no two
# may carry the same `value`. The provider only fails at apply, so catch it at plan.
check "no_duplicate_role_or_scope_values" {
  assert {
    condition = alltrue([
      for k, v in var.service_principals :
      length(concat(
        [for rk, r in v.app_roles : r.value if r.value != null],
        [for sk, s in v.permission_scopes : s.value],
        )) == length(distinct(concat(
          [for rk, r in v.app_roles : r.value if r.value != null],
          [for sk, s in v.permission_scopes : s.value],
      )))
    ])
    error_message = "Within a service principal, app_roles and permission_scopes must not share a `value` (Azure AD keeps them in one namespace)."
  }
}

# Admin consent (app role assignments and delegated grants, including the Graph shortcut) is only
# wired when a service principal exists to receive it. Flag entries that will be silently dropped
# because create_service_principal is false.
check "consent_needs_a_service_principal" {
  assert {
    condition = alltrue([
      for k, v in var.service_principals :
      v.create_service_principal ? true : (
        length(v.app_role_assignments) == 0 &&
        length(v.delegated_permission_grants) == 0 &&
        length(v.microsoft_graph_application_roles) == 0 &&
        length(v.microsoft_graph_delegated_scopes) == 0
      )
    ])
    error_message = "app_role_assignments, delegated_permission_grants and the microsoft_graph_* permissions require create_service_principal = true; they are ignored otherwise."
  }
}

# Every requested Microsoft Graph permission name must resolve against the tenant's Graph service
# principal, otherwise the id lookup fails cryptically at plan.
check "graph_permission_names_resolve" {
  assert {
    condition = alltrue([
      for k, v in var.service_principals : alltrue(concat(
        [for n in v.microsoft_graph_application_roles : contains(keys(local.graph_app_role_ids), n)],
        [for n in v.microsoft_graph_delegated_scopes : contains(keys(local.graph_scope_ids), n)],
      ))
    ])
    error_message = "One or more microsoft_graph_application_roles or microsoft_graph_delegated_scopes names do not exist on Microsoft Graph in this tenant. Check the exact published permission name."
  }
}
