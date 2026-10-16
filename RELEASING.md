# Source releases

Follow the versioned-source procedure in [CONTRIBUTING.md](CONTRIBUTING.md). The existing v0.1.0 source release identifies a unique Git revision. Validate a clean source revision with `bash scripts/ci.sh`, review all actual CI results and comments, update versioned Changes/Upgrade/Security notes in CHANGELOG.md, and publish a new immutable semantic-version tag and matching GitHub release. Include advisory identifiers when assigned.

Source publication does not apply Terraform or approve a live plan. Infrastructure operations require a separate reviewed state-aware plan, intended owner/workspace, resource identity and rollback review. Never include state, private variable files or secret-bearing plans in release assets.
