mock_provider "github" {
  override_during = plan
  mock_data "github_repository" {
    defaults = {
      visibility = "public"
      archived   = false
    }
  }
}

run "lg_bootstrap_preserves_source_provenance_and_enables_security" {
  command = plan
  assert {
    condition = (
      github_repository.ottplay_lg.name == "ottplay-lg" &&
      github_repository.ottplay_lg.visibility == "public" &&
      !github_repository.ottplay_lg.auto_init &&
      coalesce(github_repository.ottplay_lg.license_template, "unset") == "unset" &&
      github_repository.ottplay_lg.delete_branch_on_merge &&
      one(one(github_repository.ottplay_lg.security_and_analysis).secret_scanning).status == "enabled" &&
      one(one(github_repository.ottplay_lg.security_and_analysis).secret_scanning_push_protection).status == "enabled" &&
      github_repository_vulnerability_alerts.ottplay_lg.repository == "ottplay-lg" &&
      !github_repository_dependabot_security_updates.ottplay_lg.enabled
    )
    error_message = "LG must be public and empty for the licensed source bootstrap, with secret protection and vulnerability alerts, and no duplicate dependency-update producer."
  }
}

run "lg_bot_has_only_repository_write_access" {
  command = plan
  assert {
    condition = (
      github_team_repository.bots_ottplay_lg.repository == "ottplay-lg" &&
      github_team_repository.bots_ottplay_lg.permission == "push"
    )
    error_message = "The existing bot team needs only repository write access, without an administrator grant."
  }
}
