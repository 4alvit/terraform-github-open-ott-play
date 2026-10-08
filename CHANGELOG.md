# Changelog

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
