# These live per-repository settings were verified during the CI rollout.
import {
  for_each = var.read_token_repositories
  to       = github_workflow_repository_permissions.ci_defaults[each.value]
  id       = each.value
}
