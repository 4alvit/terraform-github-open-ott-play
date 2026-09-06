# terraform-github-open-ott-play

Terraform IaC for the [open-ott-play](https://github.com/open-ott-play) GitHub organization.

## Workspace

Remote state in Terraform Cloud (free tier):

| | |
|---|---|
| TFC organization | `open-ott-play` |
| Workspace | `github-open-ott-play-infrastructure` |

## Required Variables

Set these in Terraform Cloud workspace variables (not in git):

| Variable | Description | Sensitive |
|----------|-------------|-----------|
| `github_token` | GitHub PAT with `repo`, `admin:repo_hook`, `admin:org` scopes | Yes |
| `github_organization` | GitHub org name (default: `open-ott-play`) | No |
| `billing_email` | Organization billing email | Yes |

**Do not** put Cloudflare account IDs, API tokens, Worker URLs, or KV namespace IDs in this module. Those belong in the `ottplay-swop` app repo Wrangler config (local / CI secrets only).

## Managed Resources

### Repositories

- `.github` — organization profile repo
- `ottplay-foss` — IPTV/OTT set-top-box player (main project)
- `ottplay-swop` — Cloudflare Worker + KV for remote VKB text entry (TV↔phone)
- `foss-cloudflare-infrastructure` — Terraform for Cloudflare Zero Trust (Access / service tokens; secrets local-only)

`terraform-github-open-ott-play` itself lives under the `4alvit` account and is managed outside this module.

### Security (per repository)

- Vulnerability alerts (`github_repository_vulnerability_alerts`)
- Dependabot security updates (`github_repository_dependabot_security_updates`)

### Branch Protection Rulesets

Per-repo `Default` rulesets on `~DEFAULT_BRANCH` (admin bypass role id 5):

| Repo | Highlights |
|------|------------|
| `.github` | Signatures, PR reviews, CodeQL `errors` / `high_or_higher` |
| `ottplay-foss` | Signatures, PR reviews, CodeQL `none` / `none`, **required checks**: Lint, Typecheck, Build, dependency-review |
| `ottplay-swop` | Signatures, PR reviews, CodeQL `none` / `none` (add CI contexts later when workflows exist) |
| `foss-cloudflare-infrastructure` | Signatures, PR reviews, CodeQL `none` / `none` |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars  # local runs only; gitignored
terraform init
terraform plan
terraform apply
```

For normal operation use the Terraform Cloud workspace (VCS-driven or CLI-driven).

### Running locally (disconnect from Terraform Cloud)

Use this when you want `terraform plan` / `apply` on your machine **without** HCP Terraform remote execution or remote state.

This repo’s `cloud {}` block in `main.tf` targets organization `open-ott-play`, workspace `github-open-ott-play-infrastructure`.

#### Temporary detach (recommended for experiments)

1. Comment out the entire `cloud { ... }` block in `main.tf`.
2. Clear the local backend cache from the repo root:
   ```bash
   rm -rf .terraform
   ```
3. Re-init (local state by default):
   ```bash
   terraform init
   ```
4. Provide variables locally — TFC workspace variables are **not** used when detached:
   ```bash
   cp terraform.tfvars.example terraform.tfvars   # edit; gitignored
   # or: export TF_VAR_github_token=... TF_VAR_billing_email=...
   terraform plan
   terraform apply
   ```

#### Keep existing remote state locally (optional)

While still attached to TFC:

```bash
terraform state pull > terraform.tfstate
```

Then comment out `cloud {}` in `main.tf`, `rm -rf .terraform`, `terraform init`, and confirm with `terraform state list`. Keep `terraform.tfstate` **gitignored** — never commit it.

#### Warnings

- Do not apply from both TFC and local against the same resources without coordinating state (drift / conflicts).
- To re-enable TFC: uncomment `cloud {}`, remove local `.terraform` (and local state if migrating back), then `terraform init`. Only `state push` / migrate if you know what you are doing.
- Never commit credentials, `terraform.tfvars` with secrets, or state files.

Requires Terraform ≥ 1.5 (HCP Terraform `cloud {}` block; not the old `backend "remote"` syntax).
