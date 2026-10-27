#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
temporary=$(mktemp -d "${TMPDIR:-/tmp}/control-server-ruleset-test.XXXXXX")
trap 'rm -rf "$temporary"' EXIT
mkdir -p "$temporary/tests" "$temporary/provider-cache"
touch "$temporary/empty.tfrc"
# Exclude the config-driven import and every backend/credential input.
cp control-server-ruleset.tf tests/release-governance/main.tf "$temporary/"
cp tests/control-server-ruleset.tftest.hcl "$temporary/tests/"
cp .terraform.lock.hcl "$temporary/"
test_terraform() {
  env -i PATH="$PATH" HOME="$temporary" TF_IN_AUTOMATION=1 TF_INPUT=0 \
    TF_CLI_CONFIG_FILE="$temporary/empty.tfrc" TF_PLUGIN_CACHE_DIR="$temporary/provider-cache" \
    terraform -chdir="$temporary" "$@"
}
test_terraform init -backend=false -input=false -lockfile=readonly -no-color
test_terraform test -no-color
