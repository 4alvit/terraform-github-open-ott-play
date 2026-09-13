# Existing public repository, adopted with its current settings. Its release CI
# gate is declared in release-standards.tf; it has no separate Default ruleset.
resource "github_repository" "ottplay_web_vitrine" {
  name        = "ottplay-web-vitrine"
  description = "here.now web vitrine for OttPlay FOSS player (player.ottplay.here.now)"
  visibility  = "public"

  has_issues      = true
  has_projects    = true
  has_wiki        = true
  has_discussions = false

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = true
  delete_branch_on_merge = false
}

resource "github_repository_vulnerability_alerts" "ottplay_web_vitrine" {
  repository = github_repository.ottplay_web_vitrine.name
  depends_on = [github_repository.ottplay_web_vitrine]
}

resource "github_repository_dependabot_security_updates" "ottplay_web_vitrine" {
  repository = github_repository.ottplay_web_vitrine.id
  enabled    = false
}
