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
  name        = ".github"
  description = "Organization profile, community health files, and logo assets"
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

# Remote VKB text entry (TV↔phone) — Cloudflare Worker + KV.
# Cloudflare account / Worker / KV IDs and tokens are NOT managed here;
# they live in the app repo's Wrangler config (examples only, no secrets in git).

# Generic Cloudflare / Zero Trust IaC (Access apps, service tokens, tunnel notes).
# Secrets stay in the app repo's gitignored local.secrets.tfvars — not here.
resource "github_repository" "foss_cloudflare_infrastructure" {
  name        = "foss-cloudflare-infrastructure"
  description = "Terraform for Cloudflare Zero Trust (Access apps, policies, service tokens) with local-only secrets"
  visibility  = "public"

  has_issues      = true
  has_projects    = false
  has_wiki        = false
  has_discussions = false

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = true
  delete_branch_on_merge = true

  topics = [
    "cloudflare",
    "zero-trust",
    "terraform",
    "access",
    "infrastructure-as-code",
  ]

  license_template = "mit"
}

resource "github_repository_vulnerability_alerts" "foss_cloudflare_infrastructure" {
  repository = github_repository.foss_cloudflare_infrastructure.name
  depends_on = [github_repository.foss_cloudflare_infrastructure]
}

resource "github_repository_dependabot_security_updates" "foss_cloudflare_infrastructure" {
  repository = github_repository.foss_cloudflare_infrastructure.id
  enabled    = true
}

resource "github_team_repository" "bots_foss_cloudflare_infrastructure" {
  team_id    = data.github_team.bots.id
  repository = github_repository.foss_cloudflare_infrastructure.name
  permission = "push"
}

resource "github_repository" "ottplay_swop" {
  name        = "ottplay-swop"
  description = "Ephemeral remote text entry for ottplay-foss (TV↔phone) — Cloudflare Worker + KV session/poll API"
  visibility  = "public"

  has_issues      = true
  has_projects    = false
  has_wiki        = false
  has_discussions = false

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = true
  delete_branch_on_merge = true

  topics = [
    "cloudflare-workers",
    "kv",
    "ottplay",
    "iptv",
    "remote-input",
    "typescript"
  ]

  license_template = "mit"
}

resource "github_repository_vulnerability_alerts" "ottplay_swop" {
  repository = github_repository.ottplay_swop.name
  depends_on = [github_repository.ottplay_swop]
}

resource "github_repository_dependabot_security_updates" "ottplay_swop" {
  repository = github_repository.ottplay_swop.id
  enabled    = true
}

# terraform-github-open-ott-play lives under the 4alvit personal account
# (transferred out of the org) — managed outside this module.
# (State entries for it were dropped during the transfer migration.)

# =============================================================================
# Branch Protection Rulesets (per-repo — not a shared for_each)
# =============================================================================
# Split from the old for_each so ottplay-foss can require CI status checks and
# use CodeQL thresholds that match reality (none/none), while .github stays
# stricter without CI contexts.

moved {
  from = github_repository_ruleset.default[".github"]
  to   = github_repository_ruleset.profile
}

moved {
  from = github_repository_ruleset.default["ottplay-foss"]
  to   = github_repository_ruleset.ottplay_foss
}

resource "github_repository_ruleset" "profile" {
  name        = "Default"
  repository  = github_repository.profile.name
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

resource "github_repository_ruleset" "ottplay_foss" {
  name        = "Default"
  repository  = github_repository.ottplay_foss.name
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
      # Note: GitHub API also has require_extra_approval_for_unattributed_changes;
      # the Terraform github provider (~> 6) does not expose that field yet.
    }

    # Match live ottplay-foss: CodeQL present but not blocking on thresholds.
    required_code_scanning {
      required_code_scanning_tool {
        alerts_threshold          = "none"
        security_alerts_threshold = "none"
        tool                      = "CodeQL"
      }
    }

    required_status_checks {
      strict_required_status_checks_policy = false
      do_not_enforce_on_create             = false

      required_check {
        context = "Lint"
      }
      required_check {
        context = "Typecheck"
      }
      required_check {
        context = "Build"
      }
      required_check {
        context = "dependency-review"
      }
    }
  }
}

# New Worker repo: signatures + PR hygiene; no CI contexts until workflows exist.
resource "github_repository_ruleset" "ottplay_swop" {
  name        = "Default"
  repository  = github_repository.ottplay_swop.name
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
        alerts_threshold          = "none"
        security_alerts_threshold = "none"
        tool                      = "CodeQL"
      }
    }
  }
}


resource "github_repository_ruleset" "foss_cloudflare_infrastructure" {
  name        = "Default"
  repository  = github_repository.foss_cloudflare_infrastructure.name
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
        alerts_threshold          = "none"
        security_alerts_threshold = "none"
        tool                      = "CodeQL"
      }
    }
  }
}
