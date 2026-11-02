# Adopt the existing classic protection; preserve every check and publisher.
# Core PRs use the same qualification jobs once, through the required CI gate.
resource "github_branch_protection_v3" "core_main" {
  repository                      = github_repository.ottplay_core.name
  branch                          = "main"
  enforce_admins                  = false
  require_signed_commits          = false
  require_conversation_resolution = true

  required_status_checks {
    strict = true
    checks = [
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
    ]
  }

  lifecycle {
    prevent_destroy = true
  }
}
