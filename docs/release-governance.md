# Optional GitHub governance

`release-standards.tf` is an additive, explicit opt-in. The input variables default
to empty; the checked-in root `release-activation.auto.tfvars.json` explicitly opts
the reviewed public fleet in. The example `examples/release-standard.tfvars.json` lists public projects
only; merge and verify their CI gate before using any entries. It is not applied
automatically by CI or by the release installer.

The module reads current repository visibility and creates the new required-check
rulesets, immutable tag rules and reviewer environments only for public entries.
Private repositories are excluded even if an operator accidentally lists them.
No private repository requires a paid GitHub plan, Code Scanning upload, protected
reviewer environment or ruleset to run its local validation and OSS scanners.
No billing, subscription or Advanced Security feature is enabled by this module.
Existing public security/review configuration stays in place.

`RELEASE_CHANNELS_ENABLED` remains a separate ordinary Actions variable, controlled
by `release_publication_enabled_repositories`; it uses the same live public-visibility
filter as the protections. Enabled repositories must also be declared release
applications and must still be public. Variable writes wait for the selected
reviewer environments, branch policies, immutable tag rules and CI gates. Keep publication disabled until the workflow checks and deployment
hook migration have been reviewed. Private validation-only repositories publish
no beta/RC/stable artifacts. Any future private application release support needs
an explicit policy adapter; this example does not authorize it.

Review a Terraform plan before applying governance manually. Moving an already
protected repository from public to private changes the resource selection; review
that planned removal instead of assuming protections remain enforceable. Local
`bash scripts/ci.sh` uses a disposable backend-disabled validation copy and never
plans live changes, applies or changes GitHub settings.

## Public activation inventory

`release-activation.auto.tfvars.json` is the reviewed public-only inventory for
this owner, captured from the workspace fleet on 2026-09-13. It selects CI gates
for public validation and application repositories, and release environments and
immutable version tags only for application repositories. It selects no production
deployment environments. Publication remains disabled until the separate rollout
review confirms successful candidate builds and migrated deployment hooks.

The stable reviewer is `4alvit` (GitHub user ID `272257197`). The existing single
maintainer policy permits that owner to request and approve stable promotion;
`prevent_self_review=false` does not remove the required environment approval.
Release environments explicitly set `can_admins_bypass=false`, so administrators
must use the required approval instead of bypassing a waiting deployment. Other
environment types retain their existing provider default.

Use this inventory only with this repository's existing HCP Terraform workspace.
Terraform loads this root file automatically, so ordinary future plans retain the
reviewed protections without an extra CLI flag. The initial rollout must inspect
a saved targeted plan for the additive release resources before applying it:

```bash
terraform plan \
  -target=github_repository_ruleset.release_quality_gate \
  -target=github_repository_ruleset.immutable_release_tags \
  -target=github_repository_environment.release_standard \
  -target=github_repository_environment_deployment_policy.release_standard \
  -target=github_actions_variable.release_publication_enabled \
  -out=release-governance.tfplan
```

Targeting is limited to this additive rollout because the canonical workspaces also
manage unrelated repositories and organization settings. Reject deletes,
replacements, private targets, unrelated resource changes, or existing protections
that would be weakened. If an intended environment/ruleset/variable already exists
outside canonical state, inspect it and review its import before changing it; do
not create a second state owner. The saved plan may contain sensitive values and
must remain local and uncommitted. Recheck live visibility and default branches
before activation. Changing the enabled-publication set is a separate reviewed
plan after the release preconditions have passed.

`bash scripts/ci.sh` also runs six plan-only Terraform contract tests against a
mocked GitHub provider in a temporary copy with no backend or credentials. They
exercise public opt-in, default-disabled publication, private exclusion, and
rejection of private or undeclared publication targets. These tests never plan or
apply changes against a live GitHub repository or canonical Terraform state.

## Legacy release webhooks

`activation/legacy-release-webhooks.json` records the reviewed public webhook IDs,
original active/events state and narrow API payloads for this owner. These webhook
objects are not managed by this Terraform configuration or its canonical state;
the manifest is an operational policy record, not a Terraform resource or an
automatically executed migration. Verify live repository visibility and the
recorded original state before applying the payloads with the GitHub API.

Do not recreate these release subscriptions during future infrastructure work.
Release-only hooks remain disabled; shared hooks retain their unrelated event
subscriptions. Hook URLs, secrets, configuration and private receiver repositories
are deliberately outside this manifest. Candidate publication must not trigger
production deployment; stable deployment remains a separate explicit operation.
