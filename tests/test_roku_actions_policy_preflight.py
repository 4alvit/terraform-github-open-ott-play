"""Exercise the read-only Roku event-policy boundary without GitHub access."""

import json
import unittest
from types import SimpleNamespace
from unittest.mock import patch

from scripts import roku_actions_policy_preflight as preflight

HEAD = "a" * 40


class RokuActionsPolicyPreflightTests(unittest.TestCase):
    def setUp(self):
        self.responses = {
            preflight.ORGANIZATION_ENDPOINT: {"login": "open-ott-play", "plan": {"name": "free"}},
            preflight.REPO_ENDPOINT: {
                "id": preflight.REPOSITORY_ID, "full_name": preflight.REPOSITORY,
                "default_branch": "main", "visibility": "public",
                "private": False, "fork": False, "archived": False,
            },
            preflight.HEAD_ENDPOINT: {
                "ref": "refs/heads/main", "object": {"type": "commit", "sha": HEAD},
            },
            preflight.POLICIES_ENDPOINT: {"total_count": 0, "policies": []},
        }
        for workflow in preflight.WORKFLOWS:
            path = f".github/workflows/{workflow.filename}"
            self.responses[f"{preflight.REPO_ENDPOINT}/contents/{path}?ref={HEAD}"] = {
                "type": "file", "path": path, "sha": workflow.blob,
            }
            self.responses[f"{preflight.REPO_ENDPOINT}/actions/workflows/{workflow.filename}"] = {
                "path": path, "state": "active",
            }
            reusable = f".github/workflows/{workflow.reusable_filename}"
            self.responses[
                f"repos/{preflight.TOOLKIT}/contents/{reusable}?ref={preflight.TOOLKIT_COMMIT}"
            ] = {"type": "file", "path": reusable, "sha": workflow.reusable_blob}

    def test_plan_targets_two_reviewed_paths_and_preserves_recovery_events(self):
        plan = preflight.pending_plan(self.responses.__getitem__)
        self.assertEqual(plan["status"], "pending-review")
        self.assertEqual(plan["proposed_enforcement"], "evaluate")
        self.assertEqual(plan["evaluate_entitlement"], "unavailable")
        self.assertEqual(plan["repository"], "open-ott-play/ottplay-roku")
        self.assertEqual(plan["observed_head"], HEAD)
        self.assertEqual(
            {rule["path"]: rule["allowed_events"] for rule in plan["workflow_event_rules"]},
            {
                ".github/workflows/auto-approve.yml": ["pull_request_target"],
                ".github/workflows/auto-merge.yml": [
                    "pull_request_target", "workflow_run", "status", "check_run",
                    "schedule", "workflow_dispatch",
                ],
            },
        )

    def test_stops_for_metadata_and_workflow_drift(self):
        self.responses[preflight.REPO_ENDPOINT]["fork"] = True
        with self.assertRaisesRegex(ValueError, "repository identity"):
            preflight.pending_plan(self.responses.__getitem__)
        self.responses[preflight.REPO_ENDPOINT]["fork"] = False
        for endpoint in (endpoint for endpoint in self.responses if "/contents/" in endpoint):
            with (
                self.subTest(endpoint=endpoint),
                patch.dict(self.responses[endpoint], sha="b" * 40),
                self.assertRaisesRegex(ValueError, "Reviewed workflow changed"),
            ):
                preflight.pending_plan(self.responses.__getitem__)
        self.responses[f"{preflight.REPO_ENDPOINT}/actions/workflows/auto-merge.yml"]["state"] = "disabled_manually"
        with self.assertRaisesRegex(ValueError, "inactive"):
            preflight.pending_plan(self.responses.__getitem__)

    def test_stops_when_default_branch_moves_during_policy_read(self):
        def read(endpoint):
            if endpoint == preflight.POLICIES_ENDPOINT:
                self.responses[preflight.HEAD_ENDPOINT]["object"]["sha"] = "b" * 40
            return self.responses[endpoint]

        with self.assertRaisesRegex(ValueError, "moved during preflight"):
            preflight.pending_plan(read)

    def test_missing_plan_leaves_evaluate_entitlement_unverified(self):
        self.responses[preflight.ORGANIZATION_ENDPOINT].pop("plan")
        plan = preflight.pending_plan(self.responses.__getitem__)
        self.assertEqual(plan["evaluate_entitlement"], "unverified")

    def test_declines_existing_or_unreadable_inherited_policies(self):
        for response in ({"total_count": 1, "policies": [{"id": 1}]},
                         {"total_count": 0}, {"total_count": False, "policies": []}):
            with self.subTest(response=response):
                self.responses[preflight.POLICIES_ENDPOINT] = response
                with self.assertRaisesRegex(ValueError, "Actions policies require separate review"):
                    preflight.pending_plan(self.responses.__getitem__)

    def test_cli_uses_fixed_authenticated_get_without_token_argument(self):
        with patch.object(preflight.subprocess, "run", return_value=SimpleNamespace(
            stdout=json.dumps({"total_count": 0, "policies": []})
        )) as run:
            self.assertEqual(preflight.get(preflight.POLICIES_ENDPOINT)["total_count"], 0)
            run.assert_called_once_with(
                ["gh", "api", "--hostname", "github.com", "--method", "GET",
                 "-H", "X-GitHub-Api-Version: 2026-03-10", preflight.POLICIES_ENDPOINT],
                capture_output=True, text=True, check=True, timeout=20,
            )
