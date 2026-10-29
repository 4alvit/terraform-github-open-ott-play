# Android review and CI are mandatory after its workflow rollout. Other
# repositories remain staged until their approval and CI automation is verified.
variable "public_security_enforcement_repositories" {
  description = "Audited public repositories explicitly enabled for new review rules and removal of legacy administrator bypasses; owner emergency merges remain available"
  type        = set(string)
  default     = []
}

# Public software explicitly audited for the OpenSSF rollout. Private and archived
# repositories are excluded using live visibility before new rules are created.
locals {
  public_software_repositories = toset([
    "ottplay-android",
    "ottplay-control-server",
    "ottplay-core",
    "ottplay-foss",
    "ottplay-swop",
    "ottplay-web-vitrine"
  ])
  public_missing_review_repositories = toset([
    "ottplay-android",
    "ottplay-core",
    "ottplay-web-vitrine"
  ])
}

data "github_repository" "public_software" {
  for_each  = local.public_software_repositories
  full_name = "${var.github_organization}/${each.value}"
}

locals {
  active_public_software_repositories = toset([
    for repo, metadata in data.github_repository.public_software : repo
    if metadata.visibility == "public" && !metadata.archived
  ])
}

locals {
  enforced_public_security_repositories = setintersection(
    setunion(toset(["ottplay-android"]), var.public_security_enforcement_repositories),
    local.active_public_software_repositories,
  )
}

resource "github_repository_ruleset" "public_review" {
  for_each = setintersection(
    local.public_missing_review_repositories,
    local.enforced_public_security_repositories,
  )
  name        = "Public software - required review"
  repository  = each.value
  target      = "branch"
  enforcement = "active"
  # The permanent owner exception below does not grant automation a bypass.
  # Organization owners retain permanent branch recovery authority.
  bypass_actors {
    actor_id    = local.owner_emergency_merge_actor.actor_id
    actor_type  = local.owner_emergency_merge_actor.actor_type
    bypass_mode = local.owner_emergency_merge_actor.bypass_mode
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
    pull_request {
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = true
      require_last_push_approval        = true
      required_review_thread_resolution = true
    }
    dynamic "required_status_checks" {
      for_each = each.value == "ottplay-android" ? [true] : []
      content {
        strict_required_status_checks_policy = true
        required_check {
          context        = "CI gate"
          integration_id = 15368
        }
      }
    }
  }
}
