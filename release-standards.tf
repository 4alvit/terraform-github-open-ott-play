# Enable per repository only AFTER its Quality gate workflow is merged and green.
# This creates additive rules only for PUBLIC repositories, after explicit opt-in.
# Private repositories use the same local/CI checks without paid GitHub protections.
# Existing review/signature/security rules stay active.
variable "release_gate_repositories" {
  description = "Repositories migrated to the callable Quality gate workflow"
  type        = set(string)
  default     = []
}

variable "read_token_repositories" {
  description = "Audited repositories with read-only default tokens and Actions approval enabled"
  type        = set(string)
  default     = []
}

# Manage explicit repository overrides rather than broad organization defaults.
resource "github_workflow_repository_permissions" "ci_defaults" {
  for_each                         = var.read_token_repositories
  repository                       = each.value
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = true
}

variable "release_external_checks" {
  description = "Required external check names and GitHub App IDs, keyed by repository"
  type        = map(map(number))
  default     = {}
}

variable "workflow_pin_repositories" {
  description = "Public repositories whose workflow-pins tags must remain immutable"
  type        = set(string)
  default     = []
}

variable "release_channel_repositories" {
  description = "Application repositories with reviewed RC-to-stable promotion"
  type        = set(string)
  default     = []
}

variable "production_deployment_repositories" {
  description = "Repositories whose manual deploy jobs use the production environment"
  type        = set(string)
  default     = []
}

variable "release_default_branches" {
  description = "Non-main default branches, keyed by repository name"
  type        = map(string)
  default     = {}
}

variable "release_reviewer_login" {
  description = "GitHub login approving stable promotion and production deployments"
  type        = string
  default     = "4alvit"
}

# Read actual visibility so an example cannot accidentally require paid features
# after a repository becomes private. All repository sets remain empty by default.
data "github_repository" "release_standard" {
  for_each  = setunion(var.release_gate_repositories, var.release_channel_repositories, var.production_deployment_repositories, var.workflow_pin_repositories)
  full_name = "${var.github_organization}/${each.value}"

  lifecycle {
    postcondition {
      condition     = !contains(var.release_publication_enabled_repositories, each.key) || self.visibility == "public"
      error_message = "Release publication may only be enabled for a currently public repository."
    }
  }
}

locals {
  release_public_repositories = toset([
    for repo, metadata in data.github_repository.release_standard : repo
    if metadata.visibility == "public"
  ])
  protected_workflow_pin_repositories       = setintersection(var.workflow_pin_repositories, local.release_public_repositories)
  release_protected_gate_repositories       = setintersection(var.release_gate_repositories, local.release_public_repositories)
  release_protected_channel_repositories    = setintersection(var.release_channel_repositories, local.release_public_repositories)
  release_protected_deployment_repositories = setintersection(var.production_deployment_repositories, local.release_public_repositories)
}

data "github_user" "release_reviewer" {
  count    = length(setunion(local.release_protected_channel_repositories, local.release_protected_deployment_repositories)) > 0 ? 1 : 0
  username = var.release_reviewer_login
}

resource "github_repository_ruleset" "release_quality_gate" {
  for_each    = local.release_protected_gate_repositories
  name        = "Release standard - required CI gate"
  repository  = each.value
  target      = "branch"
  enforcement = "active"
  # Administrators can explicitly override CI for a reviewed pull request.
  # Direct pushes and immutable release tags do not receive this bypass.
  dynamic "bypass_actors" {
    for_each = data.github_repository.release_standard[each.key].archived ? [] : [true]
    content {
      actor_id    = 5
      actor_type  = "RepositoryRole"
      bypass_mode = "pull_request"
    }
  }
  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }
  rules {
    deletion         = true
    non_fast_forward = true
    required_status_checks {
      strict_required_status_checks_policy = true
      do_not_enforce_on_create             = false
      required_check {
        context        = "CI gate"
        integration_id = 15368
      }
      dynamic "required_check" {
        for_each = lookup(var.release_external_checks, each.key, {})
        content {
          context        = required_check.key
          integration_id = required_check.value
        }
      }
    }
  }
}

resource "github_repository_ruleset" "reusable_workflow_pins" {
  for_each    = local.protected_workflow_pin_repositories
  name        = "Keep reusable workflow pins"
  repository  = each.value
  target      = "tag"
  enforcement = "active"
  conditions {
    ref_name {
      include = ["refs/tags/workflow-pins/*"]
      exclude = []
    }
  }
  rules {
    deletion = true
    update   = true
  }
}

resource "github_repository_ruleset" "immutable_release_tags" {
  for_each    = local.release_protected_channel_repositories
  name        = "Release standard - immutable version tags"
  repository  = each.value
  target      = "tag"
  enforcement = "active"
  conditions {
    ref_name {
      include = ["refs/tags/v*"]
      exclude = []
    }
  }
  rules {
    deletion         = true
    update           = true
    non_fast_forward = true
  }
}

locals {
  release_environments = merge(
    { for repo in local.release_protected_channel_repositories : "${repo}/release" => { repository = repo, environment = "release" } },
    { for repo in local.release_protected_deployment_repositories : "${repo}/production" => { repository = repo, environment = "production" } }
  )
}

resource "github_repository_environment" "release_standard" {
  for_each    = local.release_environments
  repository  = each.value.repository
  environment = each.value.environment
  # Single-maintainer workflow: the owner may request and approve a promotion.
  # Team deployments can change this to true after adding a second reviewer.
  prevent_self_review = false
  # The owner keeps administrator bypass enabled for release approvals.
  can_admins_bypass = each.value.environment == "release" ? true : null
  reviewers {
    users = [tonumber(data.github_user.release_reviewer[0].id)]
  }
  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "release_standard" {
  for_each       = local.release_environments
  repository     = each.value.repository
  environment    = github_repository_environment.release_standard[each.key].environment
  branch_pattern = lookup(var.release_default_branches, each.value.repository, "main")
}

# Keep public candidates disabled until legacy production hooks have been migrated.
# Build-only nightlies still run and retain Actions artifacts.
variable "release_publication_enabled_repositories" {
  description = "Public repositories whose release protections and deployment-hook migration are complete"
  type        = set(string)
  default     = []

  validation {
    condition     = length(setsubtract(var.release_publication_enabled_repositories, var.release_channel_repositories)) == 0
    error_message = "Every publication-enabled repository must also be listed in release_channel_repositories."
  }
}

# Apply the same public-only boundary to variables as to protections.
resource "github_actions_variable" "release_publication_enabled" {
  for_each      = local.release_protected_channel_repositories
  repository    = each.value
  variable_name = "RELEASE_CHANNELS_ENABLED"
  value         = contains(var.release_publication_enabled_repositories, each.value) ? "true" : "false"

  # A push or scheduled run may start as soon as this variable becomes true.
  # Finish reviewer/default-branch and immutable-tag protection first.
  depends_on = [
    github_repository_ruleset.release_quality_gate,
    github_repository_ruleset.immutable_release_tags,
    github_repository_environment.release_standard,
    github_repository_environment_deployment_policy.release_standard,
  ]
}
