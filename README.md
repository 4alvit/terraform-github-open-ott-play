# terraform-github-open-ott-play

Terraform IaC for the [open-ott-play](https://github.com/open-ott-play) GitHub organization.

## Workspace

Remote state in Terraform Cloud (free tier):

| | |
|---|---|
| TFC organization | `alvit` |
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
