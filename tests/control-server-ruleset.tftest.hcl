# The disposable test root excludes the import block and all backend settings.
mock_provider "github" {
  override_during = plan
  mock_data "github_repository" {
    defaults = { visibility = "public" }
  }
}

variables {
  github_organization = "open-ott-play"
}

run "preserve_existing_rule_and_bind_only_ci_app" {
  command = plan
  assert {
    condition = (
      github_repository_ruleset.control_server_main.name == "Main branch validation" &&
      github_repository_ruleset.control_server_main.repository == "ottplay-control-server" &&
      github_repository_ruleset.control_server_main.target == "branch" &&
      github_repository_ruleset.control_server_main.enforcement == "active" &&
      length(github_repository_ruleset.control_server_main.bypass_actors) == 0 &&
      toset(one(one(github_repository_ruleset.control_server_main.conditions).ref_name).include) == toset(["~DEFAULT_BRANCH"]) &&
      length(one(one(github_repository_ruleset.control_server_main.conditions).ref_name).exclude) == 0
    )
    error_message = "Keep the exact existing rule identity, default branch and no-bypass scope."
  }
  assert {
    condition = (
      one(github_repository_ruleset.control_server_main.rules).deletion &&
      one(github_repository_ruleset.control_server_main.rules).non_fast_forward &&
      one(one(github_repository_ruleset.control_server_main.rules).required_status_checks).strict_required_status_checks_policy &&
      !one(one(github_repository_ruleset.control_server_main.rules).required_status_checks).do_not_enforce_on_create &&
      one(one(one(github_repository_ruleset.control_server_main.rules).required_status_checks).required_check).context == "CI gate" &&
      one(one(one(github_repository_ruleset.control_server_main.rules).required_status_checks).required_check).integration_id == 15368
    )
    error_message = "Keep existing protections and bind the single literal CI gate to GitHub Actions."
  }
  assert {
    condition = (
      one(one(github_repository_ruleset.control_server_main.rules).pull_request).required_approving_review_count == 0 &&
      one(one(github_repository_ruleset.control_server_main.rules).pull_request).dismiss_stale_reviews_on_push &&
      !one(one(github_repository_ruleset.control_server_main.rules).pull_request).require_code_owner_review &&
      !one(one(github_repository_ruleset.control_server_main.rules).pull_request).require_last_push_approval &&
      one(one(github_repository_ruleset.control_server_main.rules).pull_request).required_review_thread_resolution &&
      toset(one(one(github_repository_ruleset.control_server_main.rules).pull_request).allowed_merge_methods) == toset(["merge", "squash", "rebase"])
    )
    error_message = "Adoption must preserve the existing zero-review and required-conversation policy."
  }
}

run "wrong_owner_is_rejected" {
  command = plan
  variables {
    github_organization = "different-owner"
  }
  expect_failures = [github_repository_ruleset.control_server_main]
}

run "private_repository_is_rejected" {
  command = plan
  override_data {
    target = data.github_repository.control_server
    values = { visibility = "private" }
  }
  expect_failures = [github_repository_ruleset.control_server_main]
}
