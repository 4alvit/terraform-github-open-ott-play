mock_provider "github" {
  override_during = plan
  mock_data "github_repository" {
    defaults = {
      visibility = "public"
      archived   = false
    }
  }
}

run "android_policy_is_mandatory_and_other_reviews_remain_staged" {
  command = plan
  assert {
    condition     = toset(keys(github_repository_ruleset.public_review)) == toset(["ottplay-android"])
    error_message = "Android must be protected by default without enabling other staged repositories."
  }
}

run "review_requires_one_current_approval_without_bypass" {
  command = plan
  variables {
    public_security_enforcement_repositories = ["ottplay-android", "ottplay-core", "ottplay-web-vitrine"]
  }
  assert {
    condition     = length(github_repository_ruleset.public_review) == 3
    error_message = "Explicit rollout must activate each selected eligible review rule."
  }
  assert {
    condition = alltrue([
      for policy in github_repository_ruleset.public_review : (
        length(policy.bypass_actors) == 0 &&
        one(one(policy.rules).pull_request).required_approving_review_count == 1 &&
        one(one(policy.rules).pull_request).dismiss_stale_reviews_on_push &&
        one(one(policy.rules).pull_request).require_last_push_approval &&
        one(one(policy.rules).pull_request).required_review_thread_resolution
      )
    ])
    error_message = "New public review rules must have no administrator/bot bypass and require current reviews."
  }
}

run "private_repository_is_excluded" {
  command = plan
  variables {
    public_security_enforcement_repositories = ["ottplay-android"]
  }
  override_data {
    target = data.github_repository.public_software["ottplay-android"]
    values = {
      visibility = "private"
      archived   = false
    }
  }
  assert {
    condition     = !contains(local.active_public_software_repositories, "ottplay-android") && !contains(keys(github_repository_ruleset.public_review), "ottplay-android")
    error_message = "Do not apply public security rules to private repositories."
  }
}

run "archived_repository_is_excluded" {
  command = plan
  variables {
    public_security_enforcement_repositories = ["ottplay-android"]
  }
  override_data {
    target = data.github_repository.public_software["ottplay-android"]
    values = {
      visibility = "public"
      archived   = true
    }
  }
  assert {
    condition     = !contains(local.active_public_software_repositories, "ottplay-android") && !contains(keys(github_repository_ruleset.public_review), "ottplay-android")
    error_message = "Do not change archived repository protections."
  }
}

run "android_requires_actual_ci_gate_without_bypass" {
  command = plan
  variables {
    public_security_enforcement_repositories = []
  }
  assert {
    condition = (
      github_repository_ruleset.public_review["ottplay-android"].enforcement == "active" &&
      toset(one(one(github_repository_ruleset.public_review["ottplay-android"].conditions).ref_name).include) == toset(["~DEFAULT_BRANCH"]) &&
      length(github_repository_ruleset.public_review["ottplay-android"].bypass_actors) == 0 &&
      one(one(github_repository_ruleset.public_review["ottplay-android"].rules).pull_request).required_approving_review_count == 1 &&
      one(one(github_repository_ruleset.public_review["ottplay-android"].rules).pull_request).dismiss_stale_reviews_on_push &&
      one(one(github_repository_ruleset.public_review["ottplay-android"].rules).pull_request).require_last_push_approval &&
      one(one(github_repository_ruleset.public_review["ottplay-android"].rules).pull_request).required_review_thread_resolution &&
      one(one(github_repository_ruleset.public_review["ottplay-android"].rules).required_status_checks).strict_required_status_checks_policy &&
      length(one(one(github_repository_ruleset.public_review["ottplay-android"].rules).required_status_checks).required_check) == 1 &&
      alltrue([for check in one(one(github_repository_ruleset.public_review["ottplay-android"].rules).required_status_checks).required_check : check.context == "CI gate" && check.integration_id == 15368])
    )
    error_message = "Android must require one current approval and its strict GitHub Actions aggregate CI gate without bypass."
  }
}
