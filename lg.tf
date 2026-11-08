# Bootstrap the native LG client empty. The source import retains its own GPL
# notices; a generated license or initial commit would replace that provenance.
# Native checks passed before activating the review and CI rules below.
resource "github_repository" "ottplay_lg" {
  name        = "ottplay-lg"
  description = "Native SDL IPTV application for LG webOS, with Classic and Modern interfaces and shared OttPlay contracts"
  visibility  = "public"
  auto_init   = false

  has_issues      = true
  has_projects    = true
  has_wiki        = false
  has_discussions = false

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = true
  delete_branch_on_merge = true

  topics = ["c", "iptv", "lg", "ottplay", "rust", "sdl", "webos"]

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.github_organization == "open-ott-play"
      error_message = "The native LG application belongs only to the open-ott-play organization."
    }
  }
}

resource "github_repository_vulnerability_alerts" "ottplay_lg" {
  repository = github_repository.ottplay_lg.name
}

# The organization uses Renovate for dependency-update pull requests.
resource "github_repository_dependabot_security_updates" "ottplay_lg" {
  repository = github_repository.ottplay_lg.id
  enabled    = false
}

resource "github_team_repository" "bots_ottplay_lg" {
  team_id    = github_team.bots.id
  repository = github_repository.ottplay_lg.name
  permission = "push"
}

# The bot follows the same current-head review and native CI requirements as
# every other contributor. No bot or administrator bypass is introduced.
resource "github_repository_ruleset" "ottplay_lg_main" {
  name        = "Main branch validation"
  repository  = github_repository.ottplay_lg.name
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
        context        = "Source contracts"
        integration_id = 15368
      }
      required_check {
        context        = "Native host tests"
        integration_id = 15368
      }
      required_check {
        context        = "CI gate"
        integration_id = 15368
      }
    }
    pull_request {
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = true
      required_review_thread_resolution = true
      allowed_merge_methods             = ["merge", "squash", "rebase"]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
