# Security Policy

## Reporting a Vulnerability

Private vulnerability reporting is enabled for this repository. Use
[Report a vulnerability](https://github.com/4alvit/terraform-github-open-ott-play/security/advisories/new)
to send a confidential report to the maintainers. Follow
[GitHub's private reporting instructions](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability)
if you need help submitting the report.

Include the affected version or commit, steps to reproduce, expected and actual
behavior, and potential impact. Remove access tokens, credentials and personal
data from examples. Do not disclose exploit details in public issues before
coordinating with the maintainers.

## Supported versions and response

The maintained default branch is supported. Report the affected commit and the
canonical state/workspace identity, without credentials or state contents.
Maintainers aim to acknowledge vulnerability reports within 14 days and arrange
a coordinated fix and disclosure. Critical issues and active exploitation take
priority. Publicly known medium-or-higher vulnerabilities must be fixed within
60 days of becoming public; confirmation does not restart that clock. Release
notes or the change record identify the fix, affected versions, mitigations and
assigned advisories. Urgent mitigation guidance can precede full disclosure.

## Cryptographic configuration and response

Use the [supported Terraform/provider TLS profile](docs/TLS_PROFILE.md), retaining certificate and hostname verification. Do not work around a failed certificate check using insecure flags. Authenticate with minimum-scope tokens held in private environment or sensitive workspace variables. Never commit a real state, plan, key or credential.

Triage reports by reproducing with synthetic inputs, assessing affected revisions and impact, testing a fix, coordinating disclosure and recording the corrected release. Credit the reporter unless anonymity is requested. There is currently no backup maintainer or tested one-week access recovery arrangement.
