terraform {

  required_version = ">= 1.15.7"

  # Remote state storage in Terraform Cloud (free tier)
  cloud {
    organization = "victron-venus"

    workspaces {
      name = "github-open-ott-play-infrastructure"
    }
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = var.github_organization
  token = var.github_token
}

# =============================================================================
# Organization Settings
# =============================================================================
# Note: Organization settings require specific admin permissions
# and are better managed via GitHub UI for free tier accounts.
# Uncomment below if you have admin:org scope on your PAT.
#
# resource "github_organization_settings" "open_ott_play" {
#   billing_email                 = var.billing_email
#   name                          = "Open OTT Play"
#   description                   = "Open-source IPTV/OTT player for set-top boxes"
#   blog                          = "https://github.com/open-ott-play"
#   location                      = "Europe"
# }

# =============================================================================
# Repositories
# =============================================================================

resource "github_repository" "profile" {
  name        = "open-ott-play"
  description = "Open-source IPTV/OTT player for set-top boxes — organization profile"
  visibility  = "public"

  has_issues      = false
  has_projects    = false
  has_wiki        = false
  has_discussions = false

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = true
  delete_branch_on_merge = true

  license_template = "mit"
}

resource "github_repository_vulnerability_alerts" "profile" {
  repository = github_repository.profile.name
  depends_on = [github_repository.profile]
}

resource "github_repository_dependabot_security_updates" "profile" {
  repository = github_repository.profile.id
  enabled    = true
}

resource "github_repository" "ottplay_foss" {
  name        = "ottplay-foss"
  description = "IPTV/OTT set-top-box player — HLS/DASH playback, EPG, M3U/Xtream/Stalker providers, webhook push commands"
  visibility  = "public"

  has_issues      = true
  has_projects    = true
  has_wiki        = true
  has_discussions = true

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = true
  delete_branch_on_merge = true

  topics = [
    "iptv", "ott", "stb", "set-top-box", "hls", "dash",
    "epg", "m3u", "xtream-codes", "stalker", "player", "typescript"
  ]

  license_template = "mit"
}

resource "github_repository_vulnerability_alerts" "ottplay_foss" {
  repository = github_repository.ottplay_foss.name
  depends_on = [github_repository.ottplay_foss]
}

resource "github_repository_dependabot_security_updates" "ottplay_foss" {
  repository = github_repository.ottplay_foss.id
  enabled    = true
}

# terraform-github-open-ott-play lives under the 4alvit personal account
# (transferred out of the org) — managed outside this module.
# (State entries for it were dropped during the transfer migration.)

# =============================================================================
# Branch Protection Rulesets
# =============================================================================

locals {
  protected_repos = [
    "open-ott-play",
    "ottplay-foss",
  ]
}

resource "github_repository_ruleset" "default" {
  for_each    = toset(local.protected_repos)
  name        = "Default"
  repository  = each.value
  target      = "branch"
  enforcement = "active"

  bypass_actors {
    actor_id    = 5
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion            = true
    non_fast_forward    = true
    required_signatures = true

    copilot_code_review {
      review_draft_pull_requests = true
      review_on_push             = true
    }

    pull_request {
      allowed_merge_methods             = ["merge", "squash", "rebase"]
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = true
      require_last_push_approval        = true
      required_approving_review_count   = 1
      required_review_thread_resolution = true
    }

    required_code_scanning {
      required_code_scanning_tool {
        alerts_threshold          = "errors"
        security_alerts_threshold = "high_or_higher"
        tool                      = "CodeQL"
      }
    }
  }
}
