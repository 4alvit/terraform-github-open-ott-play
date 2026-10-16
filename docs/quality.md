# Quality evidence and limitations

The source is MIT-licensed Terraform configuration plus Python/shell validation tooling. It is usable as source; no project-native binary is required. The HashiCorp Terraform CLI has separate BSL terms; the project does not relicense it or claim it is FLOSS. The separately tested [OpenTofu development profile](OPENTOFU.md) provides a FLOSS validation route. The GitHub provider and Go/Python cryptographic libraries have their own FLOSS licenses.

The documented CI runs formatting, provider schema validation, mocked-provider policy tests, TFLint and CodeQL for the configured languages. The strict TLS test separately runs real Terraform/provider HTTPS against a local synthetic fixture. No live infrastructure apply, production state access or independent penetration test is performed by these tests.

On 16 October 2026 the authenticated GitHub inventory contained no public issues, project security advisories, open dependency vulnerabilities or secret alerts; Code Scanning showed only Scorecard process recommendations. The maintainer confirms secure-design/common-vulnerability knowledge and no outside bug, feature or vulnerability reports in the preceding 12 months. Re-evaluate these statements when reports arrive.

Whole-source statement/branch coverage of at least 80 percent, a dedicated fuzz campaign, complete warning strictness, independent reproducible builds and a full security assurance case are not established. The published v0.1.0 is a real source release, while current automatic CI remains validation-only. Source publication does not deploy its Terraform configuration.

See [the complete cryptographic profile](TLS_PROFILE.md), [governance](../GOVERNANCE.md), and [the roadmap](../ROADMAP.md). Remote execution and custom endpoints need separate qualification; the verified local profile is not a claim about every deployment.

OpenTofu additionally surfaces the provider's deprecated `vulnerability_alerts` compatibility attribute as “Value derived from a deprecated source” in inherited repository-policy expressions and their mock assertions. This known provider6.x compatibility diagnostic is accepted for the current declared schema; it does not disable assertions or imply a failed security check. A migration to the replacement standalone resource must preserve imported ownership and will be reviewed separately. Other warnings are not covered by this exception.
