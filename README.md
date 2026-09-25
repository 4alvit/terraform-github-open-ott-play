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
- `ottplay-core` — public canonical shared core and independent ES5 client
- `ottplay-android` — public native Android and Android TV application
- `ottplay-swop` — Cloudflare Worker + KV for remote VKB text entry (TV↔phone)
- `ottplay-web-vitrine` — existing public player vitrine, adopted into canonical state
- `foss-cloudflare-infrastructure` — archived Terraform for Cloudflare Zero Trust; kept archived

`terraform-github-open-ott-play` itself lives under the `4alvit` account and is managed outside this module.

`native-repositories.tf` adopts the existing core and Android repositories with
`visibility = "public"` and preserves their repository preferences. Both have
`prevent_destroy` protection. Their history, releases and Android signing secrets
are not recreated or stored in Terraform; signing remains a main-only manual
GitHub Actions workflow with secrets held separately from the published source.

### Security

Separate security resources cover the profile, FOSS, SWOP, vitrine and archived
infrastructure repositories:

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
| `ottplay-foss` | Signatures, PR reviews, CodeQL `none` / `none`, **required check**: canonical `CI gate` (GitHub Actions app 15368) |
| `ottplay-swop` | Signatures, PR reviews, CodeQL `none` / `none` (add CI contexts later when workflows exist) |
| `foss-cloudflare-infrastructure` | Signatures, PR reviews, CodeQL `none` / `none` |

The FOSS `CI gate` requires all configured validators for code changes and accepts
only explicitly proven documentation-only skips. Its CodeQL validator still runs
for documentation changes. Individual nested job contexts are not required because
GitHub omits them when the reusable workflow is intentionally skipped.

Public repositories listed in `release_gate_repositories` also have the additive
release CI gate. Repository
administrators (role ID 5) can explicitly bypass it when merging a pull request;
normal merges still require successful strict CI. This `pull_request` grant
does not allow direct pushes and is not added to archived repositories. The
separate `Default` review rules and release-environment approval policies retain
their existing settings. Immutable release tags have no bypass.

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

`imports.tf` adopts the existing core, Android and vitrine repositories, the
vitrine's security settings, the existing bot team, and its access to `.github`
and the vitrine. Imports preserve the same remote objects. Review their full
plan together with ordinary resource changes:

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
