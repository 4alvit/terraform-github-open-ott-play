mock_provider "github" {
  override_during = plan
  mock_data "github_repository" {
    defaults = {
      visibility = "public"
      archived   = false
    }
  }
}

run "review_requires_two_current_approvals_without_bypass" {
  command = plan
  assert {
    condition = alltrue([
      for policy in github_repository_ruleset.public_review : (
        length(policy.bypass_actors) == 0 &&
        one(one(policy.rules).pull_request).required_approving_review_count == 2 &&
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
