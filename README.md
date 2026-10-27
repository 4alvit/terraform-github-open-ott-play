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
- `outpace-acestream` — public Rust AceStream engine derived from Outpace under AGPL-3.0-or-later
- `ottplay-swop` — Cloudflare Worker + KV for remote VKB text entry (TV↔phone)
- `ottplay-web-vitrine` — existing public player vitrine, adopted into canonical state

`terraform-github-open-ott-play` itself lives under the `4alvit` account and is managed outside this module.

`native-repositories.tf` adopts the existing core and Android repositories with
`visibility = "public"` and preserves their repository preferences. Both have
`prevent_destroy` protection. Their history, releases and Android signing secrets
are not recreated or stored in Terraform; signing remains a main-only manual
GitHub Actions workflow with secrets held separately from the published source.

`outpace-acestream` is an independent public repository, created empty so the
reviewed Outpace history and its AGPL-3.0-or-later notices can be imported intact.
Terraform protects the repository from destruction, enables secret scanning and
push protection, vulnerability alerts and Dependabot security updates, and grants
the existing `bots` team push access. No license template replaces the upstream
license. After its source/CI bootstrap, the default branch requires one current review
and five strict GitHub Actions contexts: `Rust lint`, `Rust test`, `A/B harness
test`, `HLS audio synthetic`, and `acestream identifier hygiene`. Source archive
and release packaging tests run inside the Rust and A/B checks. The rules have no
bypass, and published `v*` tags cannot be rewritten or deleted.

The existing `bots` team has `push` access to `ottplay-core` and `ottplay-android`
to create shared-core artifact update branches and pull requests. These existing
grants are imported, and the core repository's enabled auto-merge is preserved. This uses the
same team access model as FOSS and SWOP.

### Security

Separate security resources cover the profile, FOSS, SWOP and vitrine
repositories:

- Vulnerability alerts (`github_repository_vulnerability_alerts`)
- Dependabot security updates (`github_repository_dependabot_security_updates`)

The retired `foss-cloudflare-infrastructure` repository and its old security,
ruleset and bot-access bindings are forgotten with `destroy = false`, before
explicit deletion of the archived repository through GitHub. This avoids API
writes to read-only archived child resources and prevents Terraform from
recreating the repository. Its maintained Terraform implementation lives in
[`victron-venus/terraform-cloudflare-inverter-gateway`](https://github.com/victron-venus/terraform-cloudflare-inverter-gateway);
production Access applications, policies and tunnel routes have a separate
operator-managed infrastructure owner. Applying this GitHub configuration does
not deploy those services.
The vitrine's existing disabled Dependabot security updates are preserved.

### Branch Protection Rulesets

Per-repo `Default` rulesets on `~DEFAULT_BRANCH` (admin bypass role id 5):

| Repo | Highlights |
|------|------------|
| `.github` | Signatures, PR reviews, CodeQL `errors` / `high_or_higher` |
| `ottplay-foss` | Signatures, PR reviews, CodeQL `none` / `none`, **required check**: canonical `CI gate` (GitHub Actions app 15368) |
| `ottplay-swop` | Signatures, PR reviews, CodeQL `none` / `none` (add CI contexts later when workflows exist) |

The FOSS `CI gate` requires all configured validators for code changes and accepts
only explicitly proven documentation-only skips. Its CodeQL validator still runs
for documentation changes. Individual nested job contexts are not required because
GitHub omits them when the reusable workflow is intentionally skipped.

Public repositories listed in `release_gate_repositories` also have the additive
release CI gate. Repository
administrators (role ID 5) can explicitly bypass it when merging a pull request;
normal merges still require successful strict CI. Removal of existing
administrator exceptions and new public review rules are deferred until the
repository is explicitly added to `public_security_enforcement_repositories`.
This `pull_request` grant does not allow direct pushes and is not added to
archived repositories. The separate `Default` review rules and release-environment
approval policies retain their existing settings. Immutable release tags have no
bypass.

The desired Android policy is now mandatory: one current review and its aggregate
`CI gate`, with no bypass. Merge and verify its gate/approval workflow before
applying. The default empty activation set preserves the other staged
repositories' existing policy.

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
vitrine's security settings, the existing bot team, and its access to `.github`,
core, Android and the vitrine. Imports preserve the same remote objects. Review their full
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

## Contributions and public security

See [CONTRIBUTING.md](CONTRIBUTING.md) for bug reports, proposed changes and tests,
[SECURITY.md](SECURITY.md) for private vulnerability reports, and
[public security policy](docs/public-security.md) for review requirements,
secret protection and rollout/state ownership. OpenSSF readiness is assessed
for this infrastructure repository separately from the projects it manages.

## Maintenance and verified operation

See the [supported TLS profile](docs/TLS_PROFILE.md), [assessment evidence](docs/openssf-evidence.md), [governance](GOVERNANCE.md), [Code of Conduct](CODE_OF_CONDUCT.md), and [one-year roadmap](ROADMAP.md).

[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/15576/badge)](https://www.bestpractices.dev/projects/15576)

The [disclosed secure-provider profile](docs/SECURE_PROVIDER.md) builds a reviewed patched GitHub provider, validates an isolated source copy and supports a guarded independent local deployment with OpenTofu; production locks and state are not automatically changed. The [engine advisory assessment](docs/OPENTOFU_ADVISORIES.md) is dated and scoped.

### Existing Control Server CI rule

`control-server-import.tf` adopts the existing `Main branch validation` rule
`23684613` into `github_repository_ruleset.control_server_main`. The dedicated
resource preserves its current name, default-branch scope, no bypass, zero-review
count, conversation resolution and allowed merge methods. Its only intended
remote change is binding the literal `CI gate` to GitHub Actions App ID `15368`.
Do not add this repository to the generic release-gate set as a replacement.

Ownership must be established before adoption. Review a full saved plan with
the existing rule imported and only this app binding changed; stop on any
unrelated create, update, replacement or deletion. The mock tests exclude the
import and backend; they do not perform state adoption or prove live enforcement.
After a separately approved apply, compare every writable ruleset field through
the GitHub API, including `require_extra_approval_for_unattributed_changes=false`.
The locked provider does not represent that additional field; any provider reset
requires a separately reviewed, rule-scoped correction before acceptance.
