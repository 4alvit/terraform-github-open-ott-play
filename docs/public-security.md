# Public software security policy

`public-security.tf` lists the public repositories reviewed for this rollout.
Live metadata excludes private and archived repositories from new protections.
The required review count is one approval from a reviewer with Write access.
Automation may provide that approval. Keep this count at one when reconciling
Terraform with GitHub. New review rules and removal of existing administrator
exceptions require explicit membership in
`public_security_enforcement_repositories`, which is empty by default.
Existing checks, signatures and immutable-tag protections remain separate
requirements.

Secret scanning and push protection are enabled on the audited public repository
resources managed by this state. Private vulnerability reporting was enabled
separately through GitHub's repository API; the pinned Terraform provider does
not expose that setting. Verify it under repository security settings during
onboarding. Do not put a credential in a commit to test push protection.

## Rollout and state ownership

The selected incremental change enables `dismiss_stale_reviews_on_push` on
existing default-branch pull-request rules with a single required approval,
preserving bypass actors, Code Owners and CI/scanning requirements. The profile
CI gate is bound to the GitHub Actions app that publishes it.

State adoption imports existing workflow permissions and bot-team grants. It
preserves the core repository's enabled auto-merge. No new review rules or
administrator-bypass removals are activated by this reconciliation.

Before adding a repository to `public_security_enforcement_repositories`, verify
its required checks and permitted reviewers, including auto-approval if the
repository uses it. The core and Android repositories do not yet have the same
auto-approval workflows as FOSS and SWOP; merely importing their existing bot
access must not impose a new review blocker. The vitrine's new review rule is
also deferred to the explicit rollout. Existing protected repositories retain
their current policies until individually selected.

Review every full plan against the canonical existing state; do not apply from
empty or unrelated state. Imports must use the actual remote identities, and
an unrestricted post-apply plan must report no changes.
For each selected setting update, compare the complete current ruleset with its
reviewed baseline, save the previous body and read back the result. Complete
active code PRs before enabling the new dismissal requirement for their
repository.

Check that the existing permitted reviewers can satisfy the chosen policy;
automation approvals do not establish independent human security review. A
higher review count is not selected merely to maximize a score. Any future new
ruleset must preserve existing protections and use its actual remote identity
when imported into the owning state.

## Extra Copilot approval after Terraform

GitHub's `require_extra_approval_for_unattributed_changes` setting must be
`false`: otherwise an unattributed Copilot PR needs an extra approval even when
the configured count is one. The pinned GitHub provider does not expose this
field, and sending a ruleset without it restores GitHub's default `true`.

After a ruleset apply or creation, run the shared
[review-policy reconciliation script](https://github.com/4alvit/terraform-github-4alvit/blob/main/scripts/reconcile-review-policy.py)
with `--owner OWNER` to inspect that owner's rules. Use `--apply --backup-dir DIR`
to save the current bodies, change only review counts above one and the extra
approval flag, and verify that all other protections remain intact. Choose a new
local backup directory for each application. Rules without required approvals
keep their zero count; archived repositories stay read-only and are reported.
This step is required until the provider supports the
extra-approval field; a Terraform plan alone cannot validate it.

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
