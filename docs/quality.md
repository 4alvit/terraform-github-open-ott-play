# Quality evidence and limitations

The source is MIT-licensed Terraform configuration plus Python/shell validation tooling. It is usable as source; no project-native binary is required. The HashiCorp Terraform CLI has separate BSL terms; the project does not relicense it or claim it is FLOSS. The separately tested [OpenTofu development profile](OPENTOFU.md) provides a FLOSS validation route. The GitHub provider and Go/Python cryptographic libraries have their own FLOSS licenses.

The documented CI runs formatting, provider schema validation, mocked-provider policy tests, TFLint and CodeQL for the configured languages. The strict TLS test separately runs real Terraform/provider HTTPS against a local synthetic fixture. No live infrastructure apply, production state access or independent penetration test is performed by these tests.

On 16 October 2026 the authenticated GitHub inventory contained no public issues, project security advisories, open dependency vulnerabilities or secret alerts; Code Scanning showed only Scorecard process recommendations. The maintainer confirms secure-design/common-vulnerability knowledge and no outside bug, feature or vulnerability reports in the preceding 12 months. Re-evaluate these statements when reports arrive.

Whole-source statement/branch coverage of at least 80 percent, a dedicated fuzz campaign, complete warning strictness, independent reproducible builds and a full security assurance case are not established. The published v0.1.0 is a real source release, while current automatic CI remains validation-only. Source publication does not deploy its Terraform configuration.

See [the complete cryptographic profile](TLS_PROFILE.md), [governance](../GOVERNANCE.md), and [the roadmap](../ROADMAP.md). Remote execution and custom endpoints need separate qualification; the verified local profile is not a claim about every deployment.

OpenTofu additionally surfaces the provider's deprecated `vulnerability_alerts` compatibility attribute as “Value derived from a deprecated source” in inherited repository-policy expressions and their mock assertions. This known provider6.x compatibility diagnostic is accepted for the current declared schema; it does not disable assertions or imply a failed security check. A migration to the replacement standalone resource must preserve imported ownership and will be reviewed separately. Other warnings are not covered by this exception.

## Toolchain vulnerabilities found on 16 October 2026

The GitHub dependency alert inventory does not inspect the downloaded Go CLI/provider binaries. A separate `govulncheck -mode binary` audit found 32 symbol-level advisories in official GitHub provider 6.13.0 (Go 1.26.4), 13 in Terraform 1.16.5 (Go 1.26.8), and 16 in OpenTofu 1.13.1 (Go 1.27.1). These counts are conservative binary findings, not proof that every affected function is exploitable through this configuration. They nevertheless prevent a clean dependency-security claim until fixed or individually assessed with evidence.

Examples include GO-2026-6607 in Go TLS (fixed Go 1.26.9/1.27.2), GO-2026-6629 in x/text, and GO-2026-5932 for the unmaintained legacy OpenPGP package. A local TLS key-length test does not resolve these advisories. The official provider is still the production dependency; the OpenTofu compatibility alternative also retains its documented dependency findings. No production provider or state has been silently replaced.

Reproduce with a current `govulncheck` from `golang.org/x/vuln/cmd/govulncheck` against each exact executable: `govulncheck -mode binary /absolute/path/to/executable`. Keep the report and executable checksum, review reachable paths, then qualify fixed upstream releases or a reproducibly built source profile before claiming remediation. Passing vulnerability-remediation criteria remain unmet during that work.
