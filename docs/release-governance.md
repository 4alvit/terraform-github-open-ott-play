# Optional GitHub governance

`release-standards.tf` is an additive, explicit opt-in. All repository sets default
to empty. The example `examples/release-standard.tfvars.json` lists public projects
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
by `release_publication_enabled_repositories`; the protection filter does not set
it to true. Keep publication disabled until the workflow checks and deployment
hook migration have been reviewed. Private validation-only repositories publish
no beta/RC/stable artifacts. Any future private application release support needs
an explicit policy adapter; this example does not authorize it.

Review a Terraform plan before applying governance manually. Moving an already
protected repository from public to private changes the resource selection; review
that planned removal instead of assuming protections remain enforceable. Local
`bash scripts/ci.sh` uses a disposable backend-disabled validation copy and never
plans, applies or changes GitHub settings.
