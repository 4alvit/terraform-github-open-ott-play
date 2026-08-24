# terraform-github-open-ott-play

Terraform IaC for the [open-ott-play](https://github.com/open-ott-play) GitHub organization.

## Workspace

Remote state in Terraform Cloud (free tier):

| | |
|---|---|
| TFC organization | `victron-venus` |
| Workspace | `github-open-ott-play-infrastructure` |

## Required Variables

Set these in Terraform Cloud workspace variables:

| Variable | Description | Sensitive |
|----------|-------------|-----------|
| `github_token` | GitHub PAT with `repo`, `admin:repo_hook`, `admin:org` scopes | Yes |
| `github_organization` | GitHub org name (default: `open-ott-play`) | No |
| `billing_email` | Organization billing email | Yes |

## Managed Resources

### Repositories

- `open-ott-play` — organization profile repo
- `ottplay-foss` — IPTV/OTT set-top-box player (main project)
- `terraform-github-open-ott-play` — this Terraform module

### Security (per repository)

- Vulnerability alerts (`github_repository_vulnerability_alerts`)
- Dependabot security updates (`github_repository_dependabot_security_updates`)

### Branch Protection Rulesets

Default ruleset on every repository default branch:

- Deletion and force-push protection, required commit signatures
- Required PR: 1 approval, code owner review, last-push approval, thread resolution
- Copilot code review on push and drafts
- CodeQL required (errors / high-or-higher)
- Bypass: repository admin (id 5) and `gitar-bot` app, always

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars  # local runs only
terraform init
terraform plan
terraform apply
```

For normal operation use the Terraform Cloud workspace (VCS-driven or CLI-driven).
