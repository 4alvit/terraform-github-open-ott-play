# Disclosed secure-provider profile

The official GitHub provider 6.13.0 binary was built with Go 1.26.4 and its dependency scan contains older findings. Upstream currently offers no newer release that resolves them all. The checked-in default lock files still refer to that official binary; this change does not silently replace a production provider or alter infrastructure.

For the supported independent local deployment profile, build the same upstream 6.13.0 source commit `20728bb30c112287ac3e8243cdb0307a45c6a0a0` with Go 1.27.2 and the exact reviewed module files under `security/provider/`. This derivative is labelled 6.13.0-openssf.1, retains its MPL 2.0 upstream license, and updates x/net 0.60.0, x/text 0.42.0, x/crypto 0.57.0 and grpc 1.83.2 along with required transitive versions. The manifest pins the source archive and module-file hashes. It is a disclosed local derivative, not a claim that upstream has released a fixed binary.

## Reproduce the derivative

Install Go 1.27.2 from its official distribution and verify its published checksum. Pass its actual executable path; setting GOTOOLCHAIN alone is insufficient proof of the selected compiler. Use a new output directory outside this checkout:

```sh
python3 scripts/build_secure_provider.py --go /VERIFIED/go/bin/go \
  --output /PRIVATE/github-provider --platform linux_arm64
```

Supported target choices are linux_amd64, linux_arm64, darwin_amd64 and darwin_arm64. The builder uses verified OpenSSL 3 TLS at security level 3 for GitHub/codeload archives, rejects HTTP/off-site redirects, forces Go FIPS TLS for module/scanner downloads, and uses an isolated home/cache, rejects unsafe archive entries, excludes operator credentials, verifies module hashes, runs source govulncheck and upstream nonacceptance unit tests, then records the actual compiler and binary digest in provenance.json. Acceptance tests are intentionally excluded because they create real GitHub resources. The builder never runs Terraform, installs a provider, edits a lock file or applies infrastructure.

On 2026-10-16 the Linux ARM64 build completed with actual Go 1.27.2, no source-reachable vulnerabilities, passing nonacceptance unit tests and SHA256 `67fd0dab765543cd3f2c5214b074b996a9cebcd391da1cead4dca45ea026ce27`. Binary-only scanners may still report unused wildcard OpenPGP packages; source imports/call paths are checked independently. Subsequent vulnerability database changes can fail a new build and must be investigated, not ignored.

## Validate without touching production state

Use checksum-verified OpenTofu 1.13.1 and a matching host-platform derivative:

```sh
python3 scripts/check_secure_provider.py --tofu /VERIFIED/tofu \
  --provider-dir /PRIVATE/github-provider --platform linux_arm64
```

This helper verifies provenance against the repository manifest and binary digest, stages a temporary source copy excluding state, private variable files and symlinks, adapts the already documented OpenTofu compatibility syntax, and uses only a local provider mirror. It replaces only disposable lock files because the derivative has a different digest. It runs format, backend-disabled init and schema validation; never plan/apply or a remote backend. The original repository, lock files, credentials and resources stay untouched. Review the temporary derivative's new dependency set before any separate production migration.

The original complete CI and mock-provider plan suites still validate repository policies with the official provider schema. A separate real transport test exercises the derivative and engine with synthetic credentials and no external network: both module download and provider API paths accept RSA 2048, ordinary mode accepts RSA 2047 as calibration, and FIPS mode rejects RSA 2047 before any HTTP request. All 8 cases passed with OpenTofu 1.13.1 and the derivative on Linux ARM64. Run it on Linux using the same trusted binaries and Python cryptography:

```sh
TLS_TEST_TERRAFORM=/VERIFIED/tofu \
TLS_TEST_PROVIDER_DIR=/PRIVATE/github-provider TLS_TEST_PLATFORM=linux_arm64 \
python3 scripts/test_tls_profile.py
```

The engine is assessed separately in OPENTOFU_ADVISORIES.md. Its recent findings remain tracked; this is not an advisory-free claim for every engine feature. The secure profile is bounded to local-state initialization, validation, plan and apply and the verified GitHub provider, with GODEBUG=fips140=on and plugin AutoMTLS enabled. Remote backends, arbitrary third-party plugins and disabling verification need their own assessment.

## Complete local deployment profile

The repository's existing HCP cloud blocks execute in remote workers. A local provider override does **not** update those workers, and the old HCP configuration is not covered by this fixed profile. Do not change or migrate its state as part of these instructions.

For a new, independent local-state deployment, export reviewed source into a new private directory with `git archive HEAD | tar -x -C /NEW/PRIVATE/WORKSPACE`. In that new copy only, remove the `terraform.cloud` block, adapt required_version to allow OpenTofu 1.13.1, use the explicit provider address registry.terraform.io/integrations/github, and remove the copied .terraform.lock.hcl so the verified derivative can receive its own hash. The automated schema validator above exercises those version/address changes separately; backend selection is an operator deployment decision. Configure a separate owned GitHub target/inventory, not resources already managed by the existing HCP workspace. Supply sensitive variables privately, for example TF_VAR_github_token; do not commit them. Keep the new local state encrypted and backed up.

Use the wrapper from the reviewed original checkout for **every** command:

```sh
python3 scripts/run_secure_profile.py --tofu /VERIFIED/tofu \
  --provider-dir /PRIVATE/github-provider --platform linux_arm64 \
  --directory /NEW/PRIVATE/WORKSPACE init
python3 scripts/run_secure_profile.py --tofu /VERIFIED/tofu \
  --provider-dir /PRIVATE/github-provider --platform linux_arm64 \
  --directory /NEW/PRIVATE/WORKSPACE plan -out=reviewed.tfplan
# After the operator reviews the exact plan and approves its intended changes:
python3 scripts/run_secure_profile.py --tofu /VERIFIED/tofu \
  --provider-dir /PRIVATE/github-provider --platform linux_arm64 \
  --directory /NEW/PRIVATE/WORKSPACE apply reviewed.tfplan
```

The wrapper is qualified for the recorded official Linux ARM64 and Darwin ARM64 OpenTofu 1.13.1 binaries. It validates the engine's hash/version and the derivative's manifest/hash on every invocation, rejects HCP/remote-backend configuration, restores provider links with backend-disabled initialization, and uses a derivative-only temporary filesystem mirror. There is no fallback to the official old provider. It forces FIPS TLS, excludes ambient CLI/plugin overrides and retains only explicit variable/token inputs and verified trust-store paths. `plan`/`apply` operate on the operator-chosen local workspace and can change GitHub resources; they were **not** run against real accounts during qualification. Four actual wrapper-driven plans passed: module download and provider API access each accept a 2048-bit RSA peer and reject a 2047-bit peer before HTTP. The tests use synthetic local API responses and disposable state only.

This is a fully functional independent local deployment option. Moving an established HCP deployment to it requires a separately designed state migration, credential/access review and acceptance; this change does not perform or imply that migration.
