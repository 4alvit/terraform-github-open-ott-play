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
