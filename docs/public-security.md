# Public software security policy

## Permanent owner bypass

The owner policy approved on 2026-10-29 permits organization owners
(`OrganizationAdmin`, with no actor ID) to bypass branch requirements with
`bypass_mode = "always"`. This replaces the earlier pull-request-only exception.
The shared `owner_emergency_merge_actor` in `admin-merge-policy.tf` is attached
to each managed branch ruleset, including separate review and CI gates. A grant
on only one ruleset cannot override another applicable rule. Existing unrelated
actor exceptions are preserved; automation receives no new privileges.

Owners can merge pull requests, make direct updates, repair branch history with
force pushes, and delete branches covered by these rules. Preserve a recovery
copy before rewriting history and use an exact `--force-with-lease` expectation
so concurrent work cannot be overwritten. Record the reason and available
validation in a pull request or maintenance record and follow up on skipped checks.
The configured reviews, CI, signatures and resolved-thread requirements remain
unchanged for actors without an applicable bypass. Immutable release tags and
deployment-environment approvals are unchanged. Archived repositories remain
read-only; existing archived release gates receive no new actor. Repositories
without enforced protection need no bypass grant.

Apply only a reviewed plan against the canonical existing HCP state, then read
back every applicable repository and inherited organization ruleset. An existing
classic branch protection can still prohibit bypass; it needs its own reviewed
state-managed update. Reconcile the unsupported extra Copilot approval field as
described below, preserving the actor list. A merge of this source is not proof
that HCP or GitHub has been updated.

OpenSSF Best Practices and OpenSSF Scorecard are separate assessments. This
exception is an explicit governance tradeoff: do not claim maximum branch
protection or universal two-person review. Reassess the actual badge criteria
and published evidence after any use that skips independent review. The
presence of a badge does not approve a bypass operation.

`public-security.tf` lists the public repositories reviewed for this rollout.
Live metadata excludes private and archived repositories from new protections.
The required review count is one approval from a reviewer with Write access.
Automation may provide that approval. Keep this count at one when reconciling
Terraform with GitHub. The desired Android policy requires one current review and strict
GitHub Actions `CI gate` (`15368`) with the documented permanent owner exception. Its aggregate gate validates the
selected host/device jobs and only permits explicit documentation-only skips.
Other new review rules and removal of existing administrator exceptions require
explicit membership in `public_security_enforcement_repositories`.
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
preserves the core repository's enabled auto-merge. Android policy activation is a
separate reviewed change from state adoption;
other staged review rules remain inactive by default.

Before adding a repository to `public_security_enforcement_repositories`, verify
its required checks and permitted reviewers, including auto-approval if the
repository uses it. Android reuses the shared metadata-only bot approval on the
`automerge`
label. Merge and verify its approval workflow and aggregate `CI gate` before
applying the mandatory ruleset, then read back the live rule. Core still needs
its own verified automation before activation; importing existing bot access
alone must not impose a new review blocker. The vitrine's new review rule is
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
