# Changelog

## Unreleased

- Keep permanent organization-owner bypass on managed branch rules, including direct updates and history repair. Preserve other actor grants, configured checks, immutable tag protection and release approvals.

## [0.2.0] - 2026-10-17

### Security

- Add the explicitly labelled GitHub provider 6.13.0-openssf.1 local derivative with Go 1.27.2 and patched x/net, x/text, x/crypto and grpc dependencies. This addresses source-reachable dependency findings including GO-2026-6607 and GO-2026-6629 in the supported independent local deployment; it does not replace the official provider in existing HCP deployments.
- Document the separate, dated OpenTofu applicability assessment, strict transport checks and engine/provider integrity requirements. See [the complete profile](docs/SECURE_PROVIDER.md). No project CVE is assigned.

### Changed

- Require one approving review while preserving stale-review dismissal and existing community-profile policy.
- Reconcile existing governance without implicitly activating new policy.
- Keep coordinated CodeQL and shared CI dependencies consistent and validate with the committed provider lock.

- Document the verified strict Terraform/provider TLS profile and source-release scope.
- Add governance, conduct and a one-year roadmap without changing live infrastructure.

### Upgrade

This is a source-only release with governance and state-management changes, not an applied infrastructure plan. Review the changes from 0.1.0 before using the configuration. Preserve the existing state and workspace bindings; import only explicitly reviewed existing resource identities. Forget a state binding only after its resource is deliberately removed from configuration and its continued remote ownership is documented; otherwise Terraform can propose recreating it. Inspect a fresh state-aware plan before any apply. Never apply this source against an empty replacement state. Where documented, run the review-policy reconciliation command after Terraform to preserve the additional Copilot setting. The independently patched provider profile is opt-in and does not replace the official HCP provider automatically. Keep the prior source tag and a protected state backup for rollback.

## [0.1.0] - 2026-10-08

### Changes

- Establish the first versioned source release of the Open OTT Play GitHub configuration.
- Document public contribution, private vulnerability reporting, policy validation
  and the distinction between a source change and an applied infrastructure change.
- Define an explicit active public-code repository scope, two current approvals,
  stale-review dismissal, last-push approval, resolved discussions and no review
  bypass for that scope. Preserve private, archived and profile exclusions.
- Validate the public policy with an offline mocked provider and scan Terraform
  with the pinned TFLint ruleset.

- Pin GitHub provider 6.13.0 and verified platform hashes in version control;
  schema validation and offline policy tests use the lock file read-only.

### Upgrade

This is Terraform source, not an applied plan or a deployment. Use the versions
and commands in CONTRIBUTING.md, preserve the existing state/workspace bindings,
and review the real state-aware plan before applying. Never initialize an empty
state to apply this configuration to existing infrastructure. When importing
existing rules, use their actual IDs and retain unrelated repository settings.

### Security

The release adds source policy for secret scanning, push protection and private
vulnerability reporting, and strengthens public repository review requirements.
A source release does not assert that every remote rule has already been applied.
No project CVE is assigned to this release. See SECURITY.md for confidential reports.
