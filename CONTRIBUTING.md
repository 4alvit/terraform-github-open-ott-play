# Contributing

Open a [GitHub issue](https://github.com/4alvit/terraform-github-open-ott-play/issues) for a bug report or
proposed improvement, and submit changes through a pull request. English reports
and contributions are welcome. Include the affected commit, Terraform version,
expected and actual behavior, and redacted reproduction steps. Use
[SECURITY.md](SECURITY.md) for confidential vulnerability reports.

## Validate a change

Use Terraform 1.15.7, TFLint 0.64.0 and actionlint 1.7.12. For repositories with `scripts/ci.sh`,
run `bash scripts/ci.sh` to check source, provider schemas and offline policy
contracts. In this repository, the public policy suite can also be run directly:

```sh
terraform fmt -check -recursive
bash scripts/test-public-security.sh
tflint --config="$PWD/.tflint.hcl" --recursive
```

TFLint applies its FLOSS Terraform recommended static-analysis rules to all source roots.
Warnings fail CI; compatibility inputs and composed test fixtures have narrow, documented
annotations where a declaration is intentionally unused in isolation.

The policy suite stages source in a temporary directory and uses a mocked GitHub
provider. It neither reads production state nor applies infrastructure changes.
The provider is downloaded during initialization. The required GitHub workflow
also validates the actual configuration; examine every result for the current
PR revision before merging.

Add automated tests for major new functionality and regression tests for fixes.
Test negative cases, especially private/archived repository exclusions, bypass
permissions and release activation. Address linter and provider warnings instead
of suppressing a check globally. Keep formatting deterministic.

## Infrastructure review

Document the target owner, resource addresses, existing remote IDs, expected
settings changes and rollback in the PR. Never commit state, plans containing
secrets, credentials or unredacted operator inventories. Keep unrelated private
infrastructure and repository access unchanged. A schema test is not a production
plan: a maintainer must inspect the real state-aware plan before an apply.
Preserve existing resource identities when importing or changing configuration.

See [README.md](README.md) for configuration inputs and operating instructions,
[public software policy](docs/public-security.md) for this rollout, and
[LICENSE](LICENSE) for the contribution license.

## Versioned source releases

Published source releases use unique `vMAJOR.MINOR.PATCH` Git tags and GitHub
Releases. Follow semantic versioning: document incompatible configuration or
state migration changes explicitly; during `0.x` development, incompatible
changes increase the minor version. Never move an existing published tag.

Before publishing, validate the exact source tree, add its Changes, Upgrade and
Security sections to CHANGELOG.md, and copy that version's human-readable notes
into its GitHub Release. Include affected versions and advisory identifiers for
security fixes when available. Preserve the distinction between validation of
source and application of a state-aware infrastructure plan.

The `.bestpractices.json` file records evidence for an OpenSSF Best Practices
self-assessment. Unknown and unmet fields remain visible; the file is not an
awarded badge or an independent security certification.

## Provider dependency lock

Commit `.terraform.lock.hcl` with every reviewed provider update. Normal schema
validation and offline policy tests use `-lockfile=readonly`, so a build cannot
silently select another provider version. Update and review the lock explicitly
with `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64`;
provider upgrades additionally require an explicit dependency update and the
full validation suite. The lock records verified checksums, not credentials.
