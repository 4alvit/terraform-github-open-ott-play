mock_provider "github" {
  override_during = plan
  mock_data "github_repository" {
    defaults = {
      visibility = "public"
      archived   = false
    }
  }
}

run "core_keeps_all_publisher_bound_checks_on_single_pr_route" {
  command = plan
  assert {
    condition = toset(one(github_branch_protection_v3.core_main.required_status_checks).checks) == toset([
      "check-0 / scope / Classify changed paths:15368",
      "check-0 / portable:15368",
      "check-0 / wire-contracts:15368",
      "check-0 / browser-client:15368",
      "Analyze (actions):15368",
      "Analyze (java-kotlin):15368",
      "Analyze (javascript-typescript):15368",
      "Analyze (python):15368",
      "dependency-review:15368",
      "CodeRabbit:347564",
      "CI gate:15368",
    ])
    error_message = "Core must retain all eleven required checks and their trusted publisher IDs."
  }
  assert {
    condition = (
      github_branch_protection_v3.core_main.repository == "ottplay-core" &&
      github_branch_protection_v3.core_main.branch == "main" &&
      one(github_branch_protection_v3.core_main.required_status_checks).strict &&
      github_branch_protection_v3.core_main.require_conversation_resolution &&
      !github_branch_protection_v3.core_main.enforce_admins &&
      !github_branch_protection_v3.core_main.require_signed_commits &&
      length(github_branch_protection_v3.core_main.required_pull_request_reviews) == 0 &&
      length(github_branch_protection_v3.core_main.restrictions) == 0
    )
    error_message = "Adopting Core protection must preserve its branch, freshness, conversation, owner and review policies."
  }
}
