# Enable per repository only AFTER its Quality gate workflow is merged and green.
# This creates additive rules; existing review/signature/security rules stay active.
variable "release_gate_repositories" {
  description = "Repositories migrated to the callable Quality gate workflow"
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

data "github_user" "release_reviewer" {
  count    = length(setunion(var.release_channel_repositories, var.production_deployment_repositories)) > 0 ? 1 : 0
  username = var.release_reviewer_login
}

resource "github_repository_ruleset" "release_quality_gate" {
  for_each    = var.release_gate_repositories
  name        = "Release standard - required CI gate"
  repository  = each.value
  target      = "branch"
  enforcement = "active"
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
        context = "CI gate"
      }
    }
  }
}

resource "github_repository_ruleset" "immutable_release_tags" {
  for_each    = var.release_channel_repositories
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
    { for repo in var.release_channel_repositories : "${repo}/release" => { repository = repo, environment = "release" } },
    { for repo in var.production_deployment_repositories : "${repo}/production" => { repository = repo, environment = "production" } }
  )
}

resource "github_repository_environment" "release_standard" {
  for_each    = local.release_environments
  repository  = each.value.repository
  environment = each.value.environment
  # Single-maintainer workflow: the owner may request and approve a promotion.
  # Team deployments can change this to true after adding a second reviewer.
  prevent_self_review = false
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
  description = "Repositories whose release protections and deployment-hook migration are complete"
  type        = set(string)
  default     = []
}

resource "github_actions_variable" "release_publication_enabled" {
  for_each      = var.release_channel_repositories
  repository    = each.value
  variable_name = "RELEASE_CHANNELS_ENABLED"
  value         = contains(var.release_publication_enabled_repositories, each.value) ? "true" : "false"
}
