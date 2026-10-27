# Adopt only the existing Control Server rule. Its review policy is distinct
# from the opt-in generic release gate and must not be replaced by that policy.
data "github_repository" "control_server" {
  full_name = "${var.github_organization}/ottplay-control-server"
}

resource "github_repository_ruleset" "control_server_main" {
  name        = "Main branch validation"
  repository  = "ottplay-control-server"
  target      = "branch"
  enforcement = "active"

  # Owners may make an explicit emergency merge through an auditable PR.
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
    required_status_checks {
      strict_required_status_checks_policy = true
      do_not_enforce_on_create             = false
      required_check {
        context        = "CI gate"
        integration_id = 15368
      }
    }
    pull_request {
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
      allowed_merge_methods             = ["merge", "squash", "rebase"]
    }
  }

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.github_organization == "open-ott-play" && data.github_repository.control_server.visibility == "public"
      error_message = "The adopted rule belongs only to the existing public open-ott-play/ottplay-control-server repository."
    }
  }
}
