# Emergency merges retain the pull request and its audit trail. Existing review,
# CI, signature, history and automation policies are unchanged for normal merges.
# This actor is intentionally narrower than the repository-administrator role.
locals {
  owner_emergency_merge_actor = {
    actor_id    = null
    actor_type  = "OrganizationAdmin"
    bypass_mode = "pull_request"
  }
}
