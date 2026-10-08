# Public software security policy

`public-security.tf` lists the public repositories reviewed for this rollout.
Live metadata excludes private and archived repositories from new protections.
Existing public review rules require two approving reviews, dismiss stale
approvals and require resolution of review threads. Administrator and automation
bypass actors are removed for this scope. Missing review rules are added without
replacing existing status checks or immutable-tag rules. Existing release CI
gates require success for administrators as well as other contributors.

Secret scanning and push protection are enabled on the audited public repository
resources managed by this state. Private vulnerability reporting was enabled
separately through GitHub's repository API; the pinned Terraform provider does
not expose that setting. Verify it under repository security settings during
onboarding. Do not put a credential in a commit to test push protection.

## Rollout and state ownership

Merge the application repair PRs after their required checks succeed, then
reconcile this desired configuration with the canonical state. Do not perform a
fleet-wide apply from an empty or unrelated state. If a rule was created through
the API, import its actual repository/ruleset identity at the declared address
before applying; do not create a duplicate rule. For out-of-band setting changes,
refresh and inspect the plan to verify the source preserves them.

Two required reviews are an ongoing maintenance requirement. Automation approvals
are not evidence of an independent human security review. Do not weaken the rule
or grant a new collaborator access merely to make an old PR mergeable. Check
whether existing permitted maintainers can complete the reviews before activation.

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
