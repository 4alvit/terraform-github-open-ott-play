#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
temporary=$(mktemp -d "${TMPDIR:-/tmp}/release-governance-test.XXXXXX")
trap 'rm -rf "$temporary"' EXIT
mkdir -p "$temporary/tests" "$temporary/provider-cache"
touch "$temporary/empty.tfrc"
cp release-standards.tf tests/release-governance/main.tf "$temporary/"
cp tests/release-governance.tftest.hcl "$temporary/tests/"
if [[ -f .terraform.lock.hcl ]]; then
  cp .terraform.lock.hcl "$temporary/"
fi

# The test copy has no cloud/backend configuration. Drop credentials and ambient
# Terraform arguments, and use mock-provider plan tests with no live API calls.
test_terraform() {
  local directory="$1"
  shift
  env -i PATH="$PATH" HOME="$temporary" TF_IN_AUTOMATION=1 TF_INPUT=0 \
    TF_CLI_CONFIG_FILE="$temporary/empty.tfrc" TF_PLUGIN_CACHE_DIR="$temporary/provider-cache" \
    terraform -chdir="$directory" "$@"
}
test_terraform "$temporary" init -backend=false -input=false -no-color
test_terraform "$temporary" test -no-color

# Exercise the real root inputs without providers, credentials or remote state.
mkdir "$temporary/input-contract"
cp variables.tf tests/input-variables.tftest.hcl "$temporary/input-contract/"
test_terraform "$temporary/input-contract" init -backend=false -input=false -no-color
test_terraform "$temporary/input-contract" test -no-color
