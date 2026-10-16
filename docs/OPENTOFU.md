# FLOSS source-validation profile

OpenTofu **1.13.1** (MPL-2.0), the unchanged MPL-2.0-licensed GitHub provider **6.13.0**, Python, Git, TFLint and actionlint provide a FLOSS route for validating this source. The compatibility command is:

```sh
TOFU_BIN=/absolute/path/to/tofu python3 scripts/check_opentofu.py
```

Install the normal Python validation dependencies first (including PyYAML where required), and use a virtual environment so they remain available when the helper isolates HOME. CI uses the published checksum-verified Linux AMD64 OpenTofu binary; the local acceptance run uses the official Darwin ARM64 binary. Both binaries identify Go 1.27.1.

The helper creates a temporary source copy and makes three explicit compatibility adaptations:

1. Lower only the copied `required_version` metadata from Terraform's `>= 1.15.7` to OpenTofu `>= 1.13.1`; the original production requirement is unchanged.
2. Expand the copied short GitHub provider address to `registry.terraform.io/integrations/github`, preserving the committed provider origin, version and checksums rather than silently choosing a different registry.
3. Remove the Terraform-only `override_during = plan` mock keyword in the copied tests. OpenTofu's mock semantics are verified by running the same plan commands, positive/negative cases and assertions; no assertion or expected failure is removed.

Existing full source/schema/policy tests then run using a temporary `terraform` executable alias pointing to the verified OpenTofu binary. The helper clears ambient credentials and command options, uses a temporary HOME and empty CLI configuration, and never runs apply or changes the original source, workspace, state, backend or live repository policy. Public provider downloads are still needed.

This is a supported source-development and validation profile, not authorization to migrate an HCP workspace or production state. A production engine migration requires independent state compatibility and rollback review. The ordinary Terraform route remains supported.

The separate [TLS profile](TLS_PROFILE.md) has eight real network-isolated calibration cases. They also pass using the OpenTofu binary with `GODEBUG=fips140=on`: the module downloader and unchanged GitHub provider reject RSA-2047 before application bytes, and accept RSA-2048. CI repeats that same harness for both engines.

[OpenTofu test semantics](https://opentofu.org/docs/v1.13/cli/commands/test/) and [MPL license](https://github.com/opentofu/opentofu/blob/v1.13.1/LICENSE) describe the upstream implementation.
