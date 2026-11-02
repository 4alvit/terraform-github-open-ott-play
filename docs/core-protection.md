# Core required-check recovery

The desired policy is the `github_branch_protection_v3.core_main` resource in
`core-branch-protection.tf`. Every check carries its GitHub App ID. The Core
workflow has one PR validation route (`quality-gate.yml`); `core.yml` still owns
main-branch delivery and manual validation.

## Released-provider limitation

Provider 6.13.0 reads both `contexts` and `checks` from GitHub and sends both back
when updating imported protection. GitHub rejects duplicate names with HTTP
422, `Context must be unique per branch protection`. The same failure can occur
on provider-created resources after refresh. Upstream issue
[3420](https://github.com/integrations/terraform-provider-github/issues/3420) and
fix [3585](https://github.com/integrations/terraform-provider-github/pull/3585)
track this behavior. A merged upstream fix is not a released provider.

`contexts = []` is not a workaround: its presence conflicts with `checks` in the
released provider's schema. Removing App IDs, deleting protection, forcing
replacement, and editing Terraform state are not acceptable workarounds.

## Narrow reconciliation

Use this only after reviewing a full saved plan whose sole intended change is
Core's required-check names. A fresh read must still match the reviewed policy.

1. Read the complete live protection with
   `gh api repos/open-ott-play/ottplay-core/branches/main/protection`. Keep the
   response locally for the comparison; it contains policy, not credentials.
   Verify the strict flag, check names and App IDs, review settings, restrictions,
   owner enforcement, conversation resolution, signatures and force-push/delete
   settings against the reviewed before state. Stop on any unexplained change.
2. Translate each `checks` entry from the reviewed Terraform plan's **after**
   state into `{ "context": "<name>", "app_id": <integer> }`, splitting on the
   final colon. There must be eleven unique contexts. Construct a payload with
   only `strict: true` and this `checks` array; do not include legacy `contexts`.
3. Send that reviewed JSON using
   `gh api --method PATCH repos/open-ott-play/ottplay-core/branches/main/protection/required_status_checks --input <payload-file>`.
   This endpoint changes only required status checks. Do not PUT the entire
   protection document or send reviews, restrictions or bypass settings.
4. Read the full protection again. Compare every field. Only the four names
   below may differ, including their mirrored values in GitHub's read-only
   legacy `contexts` view. All eleven App IDs and `strict: true` must be retained.
5. Create a **new full saved Terraform plan** from the reviewed source commit,
   using the canonical HCP workspace `open-ott-play/github-open-ott-play-infrastructure`.
   A failed initial apply may already have recorded the import. Accept only a
   no-change plan or a reviewed import with no remote updates. Apply an import
   only after review; never reuse the failed plan. Confirm a final no-change plan.

The four name migrations are:

- `scope / Classify changed paths` → `check-0 / scope / Classify changed paths`
- `portable` → `check-0 / portable`
- `wire-contracts` → `check-0 / wire-contracts`
- `browser-client` → `check-0 / browser-client`

The seven other names and all App IDs remain unchanged. Each replacement is an
existing check produced by the same quality-gate implementation. Validate those
checks on the reviewed Core source before enabling the deduplicated trigger.

For a later policy change, first check whether a released provider includes the
upstream fix, qualify that upgrade, and use Terraform normally when possible.
Until then, repeat the reviewed endpoint-only reconciliation rather than
weakening the policy or using an unreviewed provider build.
