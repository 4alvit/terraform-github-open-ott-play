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

run "lg_merge_requires_independent_review_and_native_ci" {
  command = plan
  assert {
    condition = (
      github_repository.ottplay_lg.allow_auto_merge &&
      github_repository_ruleset.ottplay_lg_main.repository == "ottplay-lg" &&
      github_repository_ruleset.ottplay_lg_main.enforcement == "active" &&
      github_repository_ruleset.ottplay_lg_main.target == "branch" &&
      length(github_repository_ruleset.ottplay_lg_main.bypass_actors) == 0 &&
      toset(one(one(github_repository_ruleset.ottplay_lg_main.conditions).ref_name).include) == toset(["~DEFAULT_BRANCH"]) &&
      one(github_repository_ruleset.ottplay_lg_main.rules).deletion &&
      one(github_repository_ruleset.ottplay_lg_main.rules).non_fast_forward &&
      one(one(github_repository_ruleset.ottplay_lg_main.rules).pull_request).required_approving_review_count == 1 &&
      one(one(github_repository_ruleset.ottplay_lg_main.rules).pull_request).dismiss_stale_reviews_on_push &&
      one(one(github_repository_ruleset.ottplay_lg_main.rules).pull_request).require_last_push_approval &&
      one(one(github_repository_ruleset.ottplay_lg_main.rules).pull_request).required_review_thread_resolution
    )
    error_message = "LG merges must require independent current-head approval and resolved discussions without bypass actors."
  }
  assert {
    condition = (
      one(one(github_repository_ruleset.ottplay_lg_main.rules).required_status_checks).strict_required_status_checks_policy &&
      !one(one(github_repository_ruleset.ottplay_lg_main.rules).required_status_checks).do_not_enforce_on_create &&
      toset([for check in one(one(github_repository_ruleset.ottplay_lg_main.rules).required_status_checks).required_check : check.context]) == toset(["Source contracts", "Native host tests", "CI gate"]) &&
      alltrue([for check in one(one(github_repository_ruleset.ottplay_lg_main.rules).required_status_checks).required_check : check.integration_id == 15368])
    )
    error_message = "Require the real LG workflow contexts from GitHub Actions on an up-to-date branch."
  }
}
