# Independent AGPL-derived source project. Import the reviewed Outpace history
# separately: auto-initialization or a license template would create a competing
# root commit and would not describe the inherited license correctly.
resource "github_repository" "outpace_acestream" {
  name        = "outpace-acestream"
  description = "Independent Rust AceStream engine derived from Outpace, maintained by Open OTT Play under AGPL-3.0-or-later"
  visibility  = "public"
  auto_init   = false

  has_issues      = true
  has_projects    = false
  has_wiki        = false
  has_discussions = true

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = false
  allow_auto_merge       = true
  delete_branch_on_merge = true

  topics = ["acestream", "agpl-3-0", "hls", "iptv", "p2p", "rust", "streaming"]

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
  }
}

resource "github_repository_vulnerability_alerts" "outpace_acestream" {
  repository = github_repository.outpace_acestream.name
}

resource "github_repository_dependabot_security_updates" "outpace_acestream" {
  repository = github_repository.outpace_acestream.id
  enabled    = true
}

resource "github_team_repository" "bots_outpace_acestream" {
  team_id    = github_team.bots.id
  repository = github_repository.outpace_acestream.name
  permission = "push"
}

# Activate only after the imported main branch has passed these exact contexts.
# Match the current public-software review policy; do not add an admin/bot bypass.
resource "github_repository_ruleset" "outpace_acestream_main" {
  name        = "Public software - required review and CI"
  repository  = github_repository.outpace_acestream.name
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
          "Rust lint",
          "Rust test",
          "A/B harness test",
          "HLS audio synthetic",
          "acestream identifier hygiene",
        ])
        content {
          context        = required_check.value
          integration_id = 15368
        }
      }
    }
  }
}

resource "github_repository_ruleset" "outpace_acestream_release_tags" {
  name        = "Release standard - immutable version tags"
  repository  = github_repository.outpace_acestream.name
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
