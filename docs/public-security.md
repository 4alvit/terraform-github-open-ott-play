# Public software security policy

`public-security.tf` lists the public repositories reviewed for this rollout.
Live metadata excludes private and archived repositories from new protections.
The committed configuration also contains a proposed broader policy: two
approving reviews, removal of administrator/automation bypasses and new review
rules. Those source settings do not establish that they have been applied, and
they are not selected by the incremental rollout below. Existing checks,
signatures and immutable-tag protections remain separate requirements.

Secret scanning and push protection are enabled on the audited public repository
resources managed by this state. Private vulnerability reporting was enabled
separately through GitHub's repository API; the pinned Terraform provider does
not expose that setting. Verify it under repository security settings during
onboarding. Do not put a credential in a commit to test push protection.

## Rollout and state ownership

The selected incremental change enables `dismiss_stale_reviews_on_push` on
existing default-branch pull-request rules while preserving their required
approval counts, bypass actors, Code Owners and CI/scanning requirements. It
creates no rulesets and imports no resources. This source change also covers
`github_repository_ruleset.profile` for `open-ott-play/.github`, whose previous source would
otherwise restore stale-approval dismissal to `false`.

A broad Terraform apply remains deferred: other committed review-count and
bypass settings differ from the selected live policy. Inspect those differences
against the canonical existing state and reconcile them in a separate reviewed
change before any broader apply. Do not apply from empty or unrelated state.
For each selected setting update, compare the complete current ruleset with its
reviewed baseline, save the previous body and read back the result. Complete
active code PRs before enabling the new dismissal requirement for their
repository.

Check that the existing permitted reviewers can satisfy the chosen policy;
automation approvals do not establish independent human security review. A
higher review count is not selected merely to maximize a score. Any future new
ruleset must preserve existing protections and use its actual remote identity
when imported into the owning state.

## Trust boundaries

Terraform credentials can change repository governance; store them in the
canonical workspace's secret variables with the narrow required scope. Source
reviews must consider changed repository sets, ruleset bypasses, workflow token
permissions, release gates and remote object ownership. Validation runs use no
production state or credentials. Provider schemas and mock tests establish
configuration behavior, not the correctness of a future live apply.

## OpenSSF evidence and remaining assessment

Public Git history, the MIT license, README interfaces, contribution policy,
private reporting instructions and executable mock tests provide auditable
inputs for an OpenSSF Best Practices assessment. The new tests cover current
review requirements and exclusion of private/archived repositories. Required
CI results and actual live settings must be checked after merge.

No OpenSSF award is claimed by this document. Maintainer knowledge, external
report-response history, release-note applicability, full static-analysis scope
and all remaining mandatory criteria need individual verification. A repository
is not certified because its managed applications are certified or vice versa.
