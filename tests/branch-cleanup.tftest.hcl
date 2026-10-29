mock_provider "github" {
  override_during = plan
  mock_data "github_repository" {
    defaults = {
      visibility = "public"
      archived   = false
    }
  }
}

run "adopted_repositories_delete_merged_branches" {
  command = plan
  assert {
    condition = alltrue([
      github_repository.ottplay_core.delete_branch_on_merge,
      github_repository.ottplay_android.delete_branch_on_merge,
      github_repository.ottplay_web_vitrine.delete_branch_on_merge,
      github_repository.outpace_acestream.delete_branch_on_merge,
    ])
    error_message = "Repository adoption must retain automatic deletion of merged pull-request branches."
  }
}
