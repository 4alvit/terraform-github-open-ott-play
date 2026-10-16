#!/usr/bin/env python3
"""Validate a reviewed derivative provider in disposable source only; never apply."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

from check_opentofu import adapt_source


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tofu", type=Path, required=True)
    parser.add_argument("--provider-dir", type=Path, required=True)
    parser.add_argument(
        "--platform",
        choices=("linux_amd64", "linux_arm64", "darwin_amd64", "darwin_arm64"),
        required=True,
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    binary = args.tofu.resolve(strict=True)
    provider = args.provider_dir.resolve(strict=True)
    expected = json.loads((root / "security/provider/manifest.json").read_text())
    provenance = json.loads((provider / "provenance.json").read_text())
    for key in (
        "source_commit",
        "source_sha256",
        "go_version",
        "build_version",
        "module_files",
    ):
        if provenance.get(key) != expected[key]:
            raise SystemExit(
                "Provider provenance differs from reviewed manifest: " + key
            )
    if provenance.get("platform") != args.platform:
        raise SystemExit("Provider platform differs from requested platform")
    executable = provider / expected["binary_name"]
    if hashlib.sha256(executable.read_bytes()).hexdigest() != provenance.get(
        "binary_sha256"
    ):
        raise SystemExit("Provider binary digest differs from build provenance")
    with tempfile.TemporaryDirectory(prefix="secure-provider-validation-") as directory:
        temporary = Path(directory)
        stage = temporary / "source"
        stage.mkdir()
        stage = stage.resolve()
        names = (
            subprocess.check_output(
                ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
                cwd=root,
            )
            .decode()
            .split("\0")
        )
        for name in set(names):
            source = root / name
            if not name or not source.is_file() or source.is_symlink():
                continue
            if (
                ".terraform" in source.parts
                or ".tfstate" in source.name
                or source.name.endswith((".tfvars", ".tfvars.json"))
            ):
                continue
            target = stage / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
        for fixture in stage.glob("deployments/*/compose.redacted.yml"):
            shutil.copyfile(fixture, fixture.with_name("compose.yml"))
        for source in stage.rglob("*"):
            if source.is_file() and source.suffix in (".tf", ".hcl", ".fixture"):
                source.write_text(adapt_source(source.name, source.read_text()))
        # Only disposable locks change: the derivative is intentionally not the registry binary.
        for lock in stage.rglob(".terraform.lock.hcl"):
            lock.unlink()
        mirror = (
            temporary
            / "mirror"
            / expected["provider_address"]
            / expected["upstream_version"]
            / args.platform
        )
        mirror.mkdir(parents=True)
        shutil.copyfile(executable, mirror / executable.name)
        (mirror / executable.name).chmod(0o755)
        config = temporary / "mirror.tfrc"
        config.write_text(
            "provider_installation {\n filesystem_mirror {\n path = "
            + json.dumps(str(temporary / "mirror"))
            + "\n }\n}\n"
        )
        environment = {
            "PATH": os.environ.get("PATH", ""),
            "HOME": str(temporary),
            "TF_CLI_CONFIG_FILE": str(config),
            "TF_INPUT": "0",
            "TF_IN_AUTOMATION": "1",
            "CHECKPOINT_DISABLE": "1",
            "GODEBUG": "fips140=on",
        }
        version = subprocess.check_output(
            [str(binary), "version", "-json"], env=environment, text=True, umask=0o077
        )
        if json.loads(version).get("terraform_version") != "1.13.1":
            raise SystemExit("This profile requires OpenTofu 1.13.1")
        policy_file = root / ".release-policy.json"
        policy = json.loads(policy_file.read_text()) if policy_file.exists() else {}
        for relative in policy.get("terraform_roots", ["."]):
            work = (stage / relative).resolve()
            if not work.is_relative_to(stage) or not work.is_dir():
                raise SystemExit("Invalid source root")
            for options in (
                ["fmt", "-recursive"],
                ["init", "-backend=false", "-input=false"],
                ["validate", "-no-color"],
            ):
                subprocess.run(
                    [str(binary), *options],
                    cwd=work,
                    env=environment,
                    check=True,
                    umask=0o077,
                )
    print(
        "Patched provider source validation passed; original state, locks and resources unchanged."
    )


if __name__ == "__main__":
    main()
