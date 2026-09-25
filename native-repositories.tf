# Adopt the existing repositories without recreating their history or releases.
# Preserve their current repository preferences while publishing the source.
resource "github_repository" "ottplay_core" {
  name        = "ottplay-core"
  description = "Canonical shared OttPlay core, independent ES5 client and migration verification"
  visibility  = "public"

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

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository" "ottplay_android" {
  name        = "ottplay-android"
  description = "Native Android and Android TV IPTV application built with Kotlin, Jetpack Compose and Media3"
  visibility  = "public"

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

  lifecycle {
    prevent_destroy = true
  }
}
