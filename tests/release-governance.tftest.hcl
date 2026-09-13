# Every run is a plan against a mocked provider in a disposable standalone copy.
mock_provider "github" {
  override_during = plan
  mock_data "github_repository" {
    defaults = {
      visibility = "public"
    }
  }
  mock_data "github_user" {
    defaults = {
      id = "272257197"
    }
  }
}

run "empty_defaults_do_not_manage_repositories" {
  command = plan
  assert {
    condition = (
      length(github_repository_ruleset.release_quality_gate) == 0 &&
      length(github_repository_ruleset.immutable_release_tags) == 0 &&
      length(github_repository_environment.release_standard) == 0 &&
      length(github_actions_variable.release_publication_enabled) == 0
    )
    error_message = "Empty defaults must not create release governance resources."
  }
}

run "public_protections_keep_publication_disabled" {
  command = plan
  variables {
    release_gate_repositories    = ["app", "checks-only"]
    release_channel_repositories = ["app"]
  }
  assert {
    condition = (
      length(github_repository_ruleset.release_quality_gate) == 2 &&
      length(github_repository_ruleset.immutable_release_tags) == 1 &&
      length(github_repository_environment.release_standard) == 1 &&
      github_actions_variable.release_publication_enabled["app"].value == "false"
    )
    error_message = "Adding protections must not enable publication or create environments for validation-only repositories."
  }
  assert {
    condition = (
      one(github_repository_environment.release_standard["app/release"].reviewers).users == toset([272257197]) &&
      github_repository_environment.release_standard["app/release"].prevent_self_review == false &&
      github_repository_environment_deployment_policy.release_standard["app/release"].branch_pattern == "main"
    )
    error_message = "Keep the reviewed owner approval and default-branch-only policy."
  }
}

run "explicit_public_application_can_be_enabled" {
  command = plan
  variables {
    release_gate_repositories                = ["app"]
    release_channel_repositories             = ["app"]
    release_publication_enabled_repositories = ["app"]
  }
  assert {
    condition     = github_actions_variable.release_publication_enabled["app"].value == "true"
    error_message = "An explicitly enabled public application must receive the activation variable."
  }
}

run "private_repositories_receive_no_resources" {
  command = plan
  variables {
    release_gate_repositories    = ["private-app"]
    release_channel_repositories = ["private-app"]
  }
  override_data {
    target = data.github_repository.release_standard["private-app"]
    values = {
      visibility = "private"
    }
  }
  assert {
    condition = (
      length(github_repository_ruleset.release_quality_gate) == 0 &&
      length(github_repository_ruleset.immutable_release_tags) == 0 &&
      length(github_repository_environment.release_standard) == 0 &&
      length(github_actions_variable.release_publication_enabled) == 0
    )
    error_message = "Private repositories must not receive variables or protection changes."
  }
}

run "private_publication_is_rejected" {
  command = plan
  variables {
    release_channel_repositories             = ["private-app"]
    release_publication_enabled_repositories = ["private-app"]
  }
  override_data {
    target = data.github_repository.release_standard["private-app"]
    values = {
      visibility = "private"
    }
  }
  expect_failures = [data.github_repository.release_standard["private-app"]]
}

run "publication_requires_channel_membership" {
  command = plan
  variables {
    release_publication_enabled_repositories = ["not-a-release-app"]
  }
  expect_failures = [var.release_publication_enabled_repositories]
}
