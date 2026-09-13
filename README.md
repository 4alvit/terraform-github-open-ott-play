# terraform-github-open-ott-play

Terraform IaC for the [open-ott-play](https://github.com/open-ott-play) GitHub organization.

<!-- ci-release-process:start -->
## CI and deployment

See [CI and deployment workflow](docs/release-workflow.md) for required checks and local commands. This repository uses validation-only policy; application release channels do not apply.
<!-- ci-release-process:end -->

## Workspace

Remote state in Terraform Cloud (free tier):

| | |
|---|---|
| TFC organization | `open-ott-play` |
| Workspace | `github-open-ott-play-infrastructure` |

## Variables

Set these in Terraform Cloud workspace variables (not in git):

| Variable | Description | Sensitive |
|----------|-------------|-----------|
| `github_token` | GitHub PAT with `repo`, `admin:repo_hook`, `admin:org` scopes | Yes |
| `github_organization` | GitHub org name (default: `open-ott-play`) | No |
| `billing_email` | Optional, currently unused organization billing email (default: `null`) | Yes |

**Do not** put Cloudflare account IDs, API tokens, Worker URLs, or KV namespace IDs in this module. Those belong in the `ottplay-swop` app repo Wrangler config (local / CI secrets only).

## Managed Resources

### Repositories

- `.github` — organization profile repo
- `ottplay-foss` — IPTV/OTT set-top-box player (main project)
- `ottplay-swop` — Cloudflare Worker + KV for remote VKB text entry (TV↔phone)
- `ottplay-web-vitrine` — existing public player vitrine, adopted into canonical state
- `foss-cloudflare-infrastructure` — archived Terraform for Cloudflare Zero Trust; kept archived

`terraform-github-open-ott-play` itself lives under the `4alvit` account and is managed outside this module.

### Security (per repository)

- Vulnerability alerts (`github_repository_vulnerability_alerts`)
- Dependabot security updates (`github_repository_dependabot_security_updates`)

The archived infrastructure repository has no active vulnerability-alert resource:
GitHub disables alerts on archives, and the provider cannot refresh that resource.
Its obsolete state entry is forgotten with `destroy = false`; the repository,
ruleset and bot access remain represented. The vitrine's existing disabled
Dependabot security updates are preserved.

### Branch Protection Rulesets

Per-repo `Default` rulesets on `~DEFAULT_BRANCH` (admin bypass role id 5):

| Repo | Highlights |
|------|------------|
| `.github` | Signatures, PR reviews, CodeQL `errors` / `high_or_higher` |
| `ottplay-foss` | Signatures, PR reviews, CodeQL `none` / `none`, **required checks**: Lint, Typecheck, Build, dependency-review |
| `ottplay-swop` | Signatures, PR reviews, CodeQL `none` / `none` (add CI contexts later when workflows exist) |
| `foss-cloudflare-infrastructure` | Signatures, PR reviews, CodeQL `none` / `none` |

Every active repository also has the additive release CI gate. Both the existing
`Default` rules and these CI gates permanently allow repository administrators
(`RepositoryRole`, ID `5`, mode `always`) to override merge requirements. Release
environments also permit administrator bypass of a waiting approval while keeping
their reviewer and branch policies. Immutable release tags have no bypass.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars  # local runs only; gitignored
terraform init
terraform plan
terraform apply
```

For normal operation use the Terraform Cloud workspace (VCS-driven or CLI-driven).

### Canonical state and full drift checks

Keep the `cloud {}` block attached to organization `open-ott-play`, workspace
`github-open-ott-play-infrastructure`. An isolated Git worktree still uses that
same canonical state. Do not detach it, copy state into a second owner, or hide
differences with `ignore_changes`.

`imports.tf` adopts the existing vitrine and its security settings, the existing
bot team, and its access to `.github` and the vitrine. Imports preserve the same
remote objects. Review their full plan together with ordinary resource changes:

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform plan -detailed-exitcode
```

The final unrestricted plan must report no changes (exit code `0`). A targeted
plan is insufficient evidence of a clean workspace. Inspect live inventory too:
an object absent from configuration and state cannot appear as plan drift.
Never commit credentials, private variable files, saved plans, or state files.
For syntax and contract tests without credentials or state access, run
`bash scripts/ci.sh`.

Requires Terraform ≥ 1.15.7.
