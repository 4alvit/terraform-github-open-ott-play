"""Read the Roku workflow identities and report a pending Actions event plan."""

import argparse
import json
import re
import subprocess  # nosec B404
import sys
from typing import NamedTuple

ORGANIZATION = "open-ott-play"
ORGANIZATION_ENDPOINT = f"orgs/{ORGANIZATION}"
REPOSITORY = f"{ORGANIZATION}/ottplay-roku"
REPOSITORY_ID = 1440445211
DEFAULT_BRANCH = "main"
TOOLKIT = "victron-venus/venus-os-ci-toolkit"
TOOLKIT_COMMIT = "644806e26446879b677f69a2f9eff58850e8c11a"
REPO_ENDPOINT = f"repos/{REPOSITORY}"
HEAD_ENDPOINT = f"{REPO_ENDPOINT}/git/ref/heads/{DEFAULT_BRANCH}"
POLICIES_ENDPOINT = f"{REPO_ENDPOINT}/actions/policies?has_parents=true&per_page=100"


class Workflow(NamedTuple):
    filename: str
    blob: str
    events: tuple[str, ...]
    reusable_filename: str
    reusable_blob: str


WORKFLOWS = (
    Workflow(
        "auto-approve.yml", "2cf20f2dbb3e153cfe149eb49e2c2c31f5311de3",
        ("pull_request_target",),
        "auto-approve-reusable.yml", "3e0f431a06124f129d47fc197a9c7adf49baffaa",
    ),
    Workflow(
        "auto-merge.yml", "61ed2144c9cfdba353829d28d145508b734a8c26",
        ("pull_request_target", "workflow_run", "status", "check_run", "schedule",
         "workflow_dispatch"),
        "auto-merge.yml", "53fe39a494dfe0a60de7d0a3fc13daca305dbd9a",
    ),
)


def get(endpoint):
    """Use the existing GitHub CLI authentication without printing credentials."""
    try:
        result = subprocess.run(  # nosec B603 B607
            ["gh", "api", "--hostname", "github.com", "--method", "GET",
             "-H", "X-GitHub-Api-Version: 2026-03-10", endpoint],
            capture_output=True, text=True, check=True, timeout=20,
        )
        value = json.loads(result.stdout)
    except (OSError, subprocess.SubprocessError, ValueError) as error:
        raise ValueError(f"Could not read GitHub metadata for {endpoint}") from error
    if not isinstance(value, dict):
        raise TypeError(f"Invalid GitHub metadata for {endpoint}")
    return value


def check_repository(metadata):
    if (metadata.get("id") != REPOSITORY_ID or metadata.get("full_name") != REPOSITORY
            or metadata.get("default_branch") != DEFAULT_BRANCH
            or metadata.get("visibility") != "public" or metadata.get("private") is not False
            or metadata.get("fork") is not False or metadata.get("archived") is not False):
        raise ValueError("Roku repository identity, visibility or default branch changed")


def read_head(read):
    value = read(HEAD_ENDPOINT)
    commit = value.get("object")
    if (value.get("ref") != f"refs/heads/{DEFAULT_BRANCH}" or not isinstance(commit, dict)
            or commit.get("type") != "commit" or not isinstance(commit.get("sha"), str)
            or re.fullmatch(r"[0-9a-f]{40}", commit["sha"]) is None):
        raise ValueError("Invalid Roku default branch commit")
    return commit["sha"]


def check_workflow(read, repository, path, commit, blob):
    value = read(f"repos/{repository}/contents/{path}?ref={commit}")
    if value.get("type") != "file" or value.get("path") != path or value.get("sha") != blob:
        raise ValueError(f"Reviewed workflow changed: {repository}/{path}")


def pending_plan(read=get):
    check_repository(read(REPO_ENDPOINT))
    head = read_head(read)
    rules = []
    for workflow in WORKFLOWS:
        path = f".github/workflows/{workflow.filename}"
        reusable_path = f".github/workflows/{workflow.reusable_filename}"
        check_workflow(read, REPOSITORY, path, head, workflow.blob)
        check_workflow(read, TOOLKIT, reusable_path, TOOLKIT_COMMIT, workflow.reusable_blob)
        active = read(f"{REPO_ENDPOINT}/actions/workflows/{workflow.filename}")
        if active.get("state") != "active" or active.get("path") != path:
            raise ValueError(f"Roku workflow is inactive or unrecognized: {path}")
        rules.append({
            "path": path,
            "git_blob": workflow.blob,
            "allowed_events": list(workflow.events),
            "reusable": {"repository": TOOLKIT, "path": reusable_path,
                         "commit": TOOLKIT_COMMIT, "git_blob": workflow.reusable_blob},
        })

    organization = read(ORGANIZATION_ENDPOINT)
    if organization.get("login") != ORGANIZATION:
        raise ValueError("Roku organization identity changed")
    plan = organization.get("plan")
    evaluate_entitlement = "unverified"
    if isinstance(plan, dict) and plan.get("name") in ("free", "team"):
        evaluate_entitlement = "unavailable"

    policies = read(POLICIES_ENDPOINT)
    count = policies.get("total_count")
    if type(count) is not int or count != 0 or policies.get("policies") != []:
        raise ValueError("Existing or unreadable Actions policies require separate review")
    check_repository(read(REPO_ENDPOINT))
    if read_head(read) != head:
        raise ValueError("Roku default branch moved during preflight")

    return {
        "status": "pending-review",
        "repository": REPOSITORY,
        "repository_id": REPOSITORY_ID,
        "default_branch": DEFAULT_BRANCH,
        "observed_head": head,
        "configured_policies_including_inherited": 0,
        "proposed_enforcement": "evaluate",
        "evaluate_entitlement": evaluate_entitlement,
        "workflow_event_rules": rules,
    }


def main():
    argparse.ArgumentParser(description=__doc__).parse_args()
    try:
        plan = pending_plan()
    except (TypeError, ValueError) as error:
        print(f"Actions policy preflight stopped: {error}", file=sys.stderr)
        return 1
    print(json.dumps(plan, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
