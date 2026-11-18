# Documentation

Terraform for the open-ott-play GitHub organization: the organization profile,
repository settings and branch policy for the OTT player projects, with the CI
policy and validation toolchain that check this source.

## Repository governance

- [Core required-check recovery](core-protection.md) — the desired `core_main` branch protection resource and its required-check routes.
- [Optional GitHub governance](release-governance.md) — the additive `release-standards.tf` opt-in, its empty defaults and the activation file.
- [Public software security policy](public-security.md) — the organization-owner bypass policy and the shared admin merge actor it is attached to.

## Validation toolchain

- [FLOSS source-validation profile](OPENTOFU.md) — the OpenTofu 1.13.1, GitHub provider 6.13.0 and TFLint toolchain used to validate this source.
- [OpenTofu profile advisory assessment — 2026-10-16](OPENTOFU_ADVISORIES.md) — the advisory findings for that OpenTofu build and which operations the assessment covers.
- [Disclosed secure-provider profile](SECURE_PROVIDER.md) — the patched-provider option and why the official 6.13.0 binary keeps its findings.
- [Local-execution TLS transport profile](TLS_PROFILE.md) — the transport key policy for the maintained Terraform configurations and provider calls.

## CI and evidence

- [CI and release operations](release-workflow.md) — `.release-policy.json`, the `CI gate` status and how workflow and lockfile changes are validated.
- [CI and release policy](CI_WORKFLOW.md) — the events the Quality gate covers and what counts as a passing validation run.
- [CI orchestration](CI-ORCHESTRATION.md) — how pull-request, merge-queue, default-branch and nightly events are assigned to the gate and release pipeline.
- [Quality evidence and limitations](quality.md) — what the MIT-licensed source and its Python/shell tooling do and do not establish.
- [OpenSSF evidence](openssf-evidence.md) — the source index for reviewing the current badge assessment.
