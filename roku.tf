# Adopt the existing public repository after its three required CI contexts
# have succeeded on main. Keep its current repository preferences unchanged.
resource "github_repository" "ottplay_roku" {
  name         = "ottplay-roku"
  description  = "Native Roku client for user-supplied M3U playlists, with SceneGraph playback and reproducible sideload delivery"
  homepage_url = "https://roku.ottplay.here.now"
  visibility   = "public"
  auto_init    = false

  has_issues      = true
  has_projects    = true
  has_wiki        = false
  has_discussions = false

  allow_merge_commit          = true
  allow_squash_merge          = true
  allow_rebase_merge          = true
  allow_auto_merge            = false
  allow_update_branch         = false
  delete_branch_on_merge      = false
  web_commit_signoff_required = false
  squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
  squash_merge_commit_message = "COMMIT_MESSAGES"
  merge_commit_title          = "MERGE_MESSAGE"
  merge_commit_message        = "PR_TITLE"
  topics                      = ["brightscript", "m3u", "ottplay", "roku", "scenegraph"]

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
      error_message = "This adoption belongs only to the existing open-ott-play repository."
    }
  }
}

resource "github_repository_vulnerability_alerts" "ottplay_roku" {
  repository = github_repository.ottplay_roku.name
}

resource "github_repository_dependabot_security_updates" "ottplay_roku" {
  repository = github_repository.ottplay_roku.id
  enabled    = true
}

# The existing bot has only the organization's default read permission here.
# Use the same narrowly scoped repository write grant as the other public apps.
resource "github_team_repository" "bots_ottplay_roku" {
  team_id    = github_team.bots.id
  repository = github_repository.ottplay_roku.name
  permission = "push"
}

resource "github_repository_ruleset" "ottplay_roku_main" {
  depends_on = [github_team_repository.bots_ottplay_roku]

  name        = "Public software - required review and CI"
  repository  = github_repository.ottplay_roku.name
  target      = "branch"
  enforcement = "active"

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
    required_status_checks {
      strict_required_status_checks_policy = true
      dynamic "required_check" {
        for_each = toset([
          "BrightScript and package / Node 22.23.4",
          "BrightScript and package / Node 24.22.1",
          "scan / CodeQL Analysis",
        ])
        content {
          context        = required_check.value
          integration_id = 15368
        }
      }
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}
