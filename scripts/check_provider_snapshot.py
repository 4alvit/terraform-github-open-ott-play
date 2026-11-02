#!/usr/bin/env python3
"""Validate copied provider locks; select source qualification conservatively."""

import argparse
import json
import os
import re
import subprocess
from pathlib import Path

from build_secure_provider import validate_snapshot


def relevant(path):
    """Include all inputs that can change provider qualification behavior."""
    return path.startswith(
        ("security/provider/", ".github/workflows/", "tests/test_secure")
    ) or path in {
        ".github/dependabot.yml",
        "requirements-security-tests.txt",
        "scripts/build_secure_provider.py",
        "scripts/check_provider_snapshot.py",
        "scripts/ci.sh",
    }


def qualification_required(root, event_name, event):
    """Skip the build only after a complete, known Git diff of unrelated paths."""
    try:
        if event_name == "pull_request":
            base = event["pull_request"]["base"]["sha"]
            head = event["pull_request"]["head"]["sha"]
            separator = "..."
        elif event_name == "push":
            base, head = event["before"], event["after"]
            separator = ".."
        elif event_name == "merge_group":
            base = event["merge_group"]["base_sha"]
            head = event["merge_group"]["head_sha"]
            separator = ".."
        else:
            return True
        if not all(
            isinstance(v, str) and re.fullmatch(r"[0-9a-f]{40}", v)
            for v in (base, head)
        ):
            return True
        environment = {
            **os.environ,
            "GIT_NO_REPLACE_OBJECTS": "1",
            "GIT_OPTIONAL_LOCKS": "0",
        }

        def git(*args):
            return subprocess.check_output(
                ["git", *args],
                cwd=root,
                env=environment,
                timeout=30,
                stderr=subprocess.DEVNULL,
            )

        if git("rev-parse", "--is-shallow-repository").strip() != b"false":
            return True
        for revision in (base, head):
            if git("cat-file", "-t", revision).strip() != b"commit":
                return True
        changes = git(
            "diff",
            "--name-only",
            "--no-renames",
            "--no-ext-diff",
            "--no-textconv",
            "-z",
            base + separator + head,
            "--",
        )
        if not changes or len(changes) > 2 * 1024 * 1024 or not changes.endswith(b"\0"):
            return True
        return any(
            relevant(name) for name in changes.decode("utf-8").rstrip("\0").split("\0")
        )
    except (KeyError, TypeError, ValueError, OSError, subprocess.SubprocessError):
        return True


def main():
    """Run the offline guard on every CI invocation, including unrelated changes."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--github-output", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    pinned = root / "security/provider"
    count = validate_snapshot(
        pinned, json.loads((pinned / "manifest.json").read_text())
    )
    print(
        f"Provider snapshot verified: {count} requirements with module and archive checksums"
    )
    if args.github_output:
        try:
            event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
        except (KeyError, OSError, ValueError):
            event = None
        required = qualification_required(
            root, os.environ.get("GITHUB_EVENT_NAME"), event
        )
        with Path(os.environ["GITHUB_OUTPUT"]).open("a", encoding="utf-8") as output:
            output.write(f"qualify={str(required).lower()}\n")
        print(f"Provider source qualification required: {required}")


if __name__ == "__main__":
    main()
