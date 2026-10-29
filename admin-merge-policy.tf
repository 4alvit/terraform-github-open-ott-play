# Organization owners retain permanent branch recovery authority, including
# direct updates and history repair. Existing rules and unrelated actor grants
# remain unchanged; immutable tag rules do not use this exception.
locals {
  owner_emergency_merge_actor = {
    actor_id    = null
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }
}
