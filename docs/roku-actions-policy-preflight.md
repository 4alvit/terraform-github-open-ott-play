# Roku Actions event policy preflight

GitHub will enforce the default public-repository block on `pull_request_target`
on December 2, 2026, where there is no applicable event policy. For Roku, the
reviewed pilot covers two existing metadata-only callers. [GitHub announcement](https://github.blog/changelog/2026-11-02-pull_request_target-blocked-by-default-december-2/)

From the root of this repository, run the preflight with Python and an authenticated
GitHub CLI account that can read Roku's Actions policies.

```sh
python3 scripts/roku_actions_policy_preflight.py
```

The command uses GET requests for the public, non-fork `open-ott-play/ottplay-roku`
repository with ID `1440445211`. It compares the exact approved workflow file blobs
at the current `main` commit with the approved immutable Toolkit reusable workflow
blobs. It also checks that the callers are active and that the current repository
has zero configured Actions policies, including inherited policies. A changed
identity, disabled workflow, moved head within the observation, unreadable API
result or existing policy stops the command. Different workflows need their own
source review.

The JSON result is a pending proposal with one narrow event set per path.
GitHub documents Evaluate mode as Enterprise-only. The preflight reports it as
`unavailable` when GitHub returns a Free or Team organization plan and
`unverified` otherwise. Keep the proposal pending until eligibility is confirmed.
[GitHub Actions policies API](https://docs.github.com/en/rest/actions/policies)

- `.github/workflows/auto-approve.yml` uses `pull_request_target`.
- `.github/workflows/auto-merge.yml` uses `pull_request_target`, `workflow_run`,
  `status`, `check_run`, `schedule` and `workflow_dispatch`. The last five events
  preserve the existing check-completion and recovery paths.

Both callers limit PR target events to same-repository pull requests from
`4alvit`, `californiantiramisu`, `dependabot[bot]` and `renovate[bot]`.
The pinned reusable workflows check current GitHub metadata before reviews or
merges. The preflight emits a report for review using read-only API requests.

Before any later activation, run the preflight again against live metadata.
Review the Evaluate observations with a trusted same-repository PR, including
approval, required checks and label withdrawal. A fork must stay outside the
automation's same-repository scope.
