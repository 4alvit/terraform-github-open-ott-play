mock_provider "github" {
  override_during = plan
  mock_data "github_repository" {
    defaults = {
      visibility = "public"
      archived   = false
    }
  }
}

run "outpace_requires_current_review_and_exact_build_source_checks" {
  command = plan
  assert {
    condition = (
      github_repository_ruleset.outpace_acestream_main.enforcement == "active" &&
      (
        length([for actor in github_repository_ruleset.outpace_acestream_main.bypass_actors : actor if actor.actor_type == local.owner_emergency_merge_actor.actor_type]) == 1 &&
        alltrue([
          for actor in github_repository_ruleset.outpace_acestream_main.bypass_actors :
          coalesce(actor.actor_id, 0) == coalesce(local.owner_emergency_merge_actor.actor_id, 0) && actor.bypass_mode == "always"
          if actor.actor_type == local.owner_emergency_merge_actor.actor_type
        ]) &&
        length([for actor in github_repository_ruleset.outpace_acestream_main.bypass_actors : actor if actor.actor_type != local.owner_emergency_merge_actor.actor_type]) == 0
      ) &&
      toset(one(one(github_repository_ruleset.outpace_acestream_main.conditions).ref_name).include) == toset(["~DEFAULT_BRANCH"]) &&
      one(github_repository_ruleset.outpace_acestream_main.rules).deletion &&
      one(github_repository_ruleset.outpace_acestream_main.rules).non_fast_forward &&
      one(one(github_repository_ruleset.outpace_acestream_main.rules).pull_request).required_approving_review_count == 1 &&
      one(one(github_repository_ruleset.outpace_acestream_main.rules).pull_request).dismiss_stale_reviews_on_push &&
      one(one(github_repository_ruleset.outpace_acestream_main.rules).pull_request).require_last_push_approval &&
      one(one(github_repository_ruleset.outpace_acestream_main.rules).pull_request).required_review_thread_resolution &&
      one(one(github_repository_ruleset.outpace_acestream_main.rules).required_status_checks).strict_required_status_checks_policy &&
      toset([for check in one(one(github_repository_ruleset.outpace_acestream_main.rules).required_status_checks).required_check : check.context]) == toset([
        "Rust lint", "Rust test", "A/B harness test", "HLS audio synthetic", "acestream identifier hygiene"
      ]) &&
      alltrue([for check in one(one(github_repository_ruleset.outpace_acestream_main.rules).required_status_checks).required_check : check.integration_id == 15368])
    )
    error_message = "Outpace must require current review and its five verified Actions contexts with the documented owner exception."
  }
}

run "outpace_release_tags_are_immutable_without_bypass" {
  command = plan
  assert {
    condition = (
      github_repository_ruleset.outpace_acestream_release_tags.enforcement == "active" &&
      github_repository_ruleset.outpace_acestream_release_tags.target == "tag" &&
      length(github_repository_ruleset.outpace_acestream_release_tags.bypass_actors) == 0 &&
      toset(one(one(github_repository_ruleset.outpace_acestream_release_tags.conditions).ref_name).include) == toset(["refs/tags/v*"]) &&
      one(github_repository_ruleset.outpace_acestream_release_tags.rules).deletion &&
      one(github_repository_ruleset.outpace_acestream_release_tags.rules).update &&
      one(github_repository_ruleset.outpace_acestream_release_tags.rules).non_fast_forward
    )
    error_message = "Published Outpace version tags must not be rewritten or deleted by normal or bypass actors."
  }
}
