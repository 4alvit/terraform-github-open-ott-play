#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/validate-source.py
python3 -m unittest discover -s tests -p 'test_workflow_contracts.py'
python3 scripts/validate-terraform.py
bash scripts/test-release-governance.sh
bash scripts/test-public-security.sh
tflint --config="$PWD/.tflint.hcl" --recursive
