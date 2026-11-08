# Bootstrap the native LG client empty. The source import retains its own GPL
# notices; a generated license or initial commit would replace that provenance.
# Activate branch review/CI rules only after the real workflow contexts pass.
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
  allow_auto_merge       = false
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
