mock_provider "github" {
  override_during = plan
  mock_data "github_repository" {
    defaults = {
      visibility = "public"
      archived   = false
    }
  }
}

run "roku_adoption_preserves_repository_preferences_and_enables_security" {
  command = plan
  assert {
    condition = (
      github_repository.ottplay_roku.name == "ottplay-roku" &&
      github_repository.ottplay_roku.visibility == "public" &&
      !github_repository.ottplay_roku.auto_init &&
      github_repository.ottplay_roku.homepage_url == "https://roku.ottplay.here.now" &&
      github_repository.ottplay_roku.has_issues &&
      github_repository.ottplay_roku.has_projects &&
      !github_repository.ottplay_roku.has_wiki &&
      !github_repository.ottplay_roku.has_discussions &&
      github_repository.ottplay_roku.allow_merge_commit &&
      github_repository.ottplay_roku.allow_squash_merge &&
      github_repository.ottplay_roku.allow_rebase_merge &&
      !github_repository.ottplay_roku.allow_auto_merge &&
      !github_repository.ottplay_roku.allow_update_branch &&
      !github_repository.ottplay_roku.delete_branch_on_merge &&
      !github_repository.ottplay_roku.web_commit_signoff_required &&
      one(one(github_repository.ottplay_roku.security_and_analysis).secret_scanning).status == "enabled" &&
      one(one(github_repository.ottplay_roku.security_and_analysis).secret_scanning_push_protection).status == "enabled" &&
      !github_repository_dependabot_security_updates.ottplay_roku.enabled
    )
    error_message = "Roku adoption must preserve the existing public repository preferences and its enabled security features."
  }
}

run "roku_requires_one_current_review_and_exact_publisher_bound_checks" {
  command = plan
  assert {
    condition = (
      github_repository_ruleset.ottplay_roku_main.enforcement == "active" &&
      github_repository_ruleset.ottplay_roku_main.target == "branch" &&
      toset(one(one(github_repository_ruleset.ottplay_roku_main.conditions).ref_name).include) == toset(["~DEFAULT_BRANCH"]) &&
      one(github_repository_ruleset.ottplay_roku_main.rules).deletion &&
      one(github_repository_ruleset.ottplay_roku_main.rules).non_fast_forward &&
      one(one(github_repository_ruleset.ottplay_roku_main.rules).pull_request).required_approving_review_count == 1 &&
      one(one(github_repository_ruleset.ottplay_roku_main.rules).pull_request).dismiss_stale_reviews_on_push &&
      one(one(github_repository_ruleset.ottplay_roku_main.rules).pull_request).require_last_push_approval &&
      one(one(github_repository_ruleset.ottplay_roku_main.rules).pull_request).required_review_thread_resolution &&
      one(one(github_repository_ruleset.ottplay_roku_main.rules).required_status_checks).strict_required_status_checks_policy &&
      toset([for check in one(one(github_repository_ruleset.ottplay_roku_main.rules).required_status_checks).required_check : check.context]) == toset([
        "BrightScript and package / Node 22.23.4",
        "BrightScript and package / Node 24.22.1",
        "scan / CodeQL Analysis",
      ]) &&
      alltrue([for check in one(one(github_repository_ruleset.ottplay_roku_main.rules).required_status_checks).required_check : check.integration_id == 15368])
    )
    error_message = "Roku must require one current approval and all three verified GitHub Actions checks, without substituting untrusted statuses."
  }
  assert {
    condition = (
      length(github_repository_ruleset.ottplay_roku_main.bypass_actors) == 1 &&
      one(github_repository_ruleset.ottplay_roku_main.bypass_actors).actor_type == "OrganizationAdmin" &&
      one(github_repository_ruleset.ottplay_roku_main.bypass_actors).actor_id == null &&
      one(github_repository_ruleset.ottplay_roku_main.bypass_actors).bypass_mode == "always"
    )
    error_message = "Only the existing organization-owner exception may bypass Roku's branch policy."
  }
}

run "roku_bot_has_review_write_access_without_admin_bypass" {
  command = plan
  assert {
    condition = (
      github_team_repository.bots_ottplay_roku.repository == "ottplay-roku" &&
      github_team_repository.bots_ottplay_roku.permission == "push"
    )
    error_message = "The existing bot team needs repository write access for its required review, never an administrator grant."
  }
}

run "roku_adoption_rejects_another_organization" {
  command = plan
  variables {
    github_organization = "another-organization"
  }
  # Both platform onboarding resources are confined to this organization.
  expect_failures = [github_repository.ottplay_roku, github_repository.ottplay_lg]
}
