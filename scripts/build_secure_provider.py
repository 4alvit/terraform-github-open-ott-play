#!/usr/bin/env python3
"""Build a disclosed provider patch; never install it, mutate locks or run Terraform."""

import argparse
import hashlib
import json
import os
import re
import shutil
import ssl
import subprocess
import tarfile
import tempfile
import urllib.request
from pathlib import Path
from urllib.parse import urlsplit


def digest(path):
    """Return the integrity digest for a local artifact."""
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_snapshot(pinned, manifest):
    """Reject an empty or incomplete copied module even if its hashes were updated."""
    if set(manifest["module_files"]) != {"go.mod", "go.sum"}:
        raise ValueError("The provider snapshot must contain go.mod and go.sum")
    for name, expected in manifest["module_files"].items():
        if digest(pinned / name) != expected:
            raise ValueError(f"Pinned module-file checksum mismatch: {name}")
    module = (pinned / "go.mod").read_text()
    if not re.search(
        r"^module github\.com/integrations/terraform-provider-github/v6\s*$",
        module,
        re.MULTILINE,
    ):
        raise ValueError("Unexpected provider module")
    requirements = []
    in_block = False
    for line in module.splitlines():
        line = line.split("//", 1)[0].strip()
        if line == "require (":
            in_block = True
        elif in_block and line == ")":
            in_block = False
        elif line.startswith("require ") or (in_block and line):
            fields = line.removeprefix("require ").split()
            if len(fields) != 2 or not fields[1].startswith("v"):
                raise ValueError("Malformed provider requirement")
            requirements.append(tuple(fields))
    if (
        in_block
        or not requirements
        or len({name for name, _ in requirements}) != len(requirements)
    ):
        raise ValueError("Provider requirements are empty, incomplete or duplicated")
    sums = set()
    for line in (pinned / "go.sum").read_text().splitlines():
        fields = line.split()
        if len(fields) != 3 or not re.fullmatch(r"h1:[A-Za-z0-9+/]{43}=", fields[2]):
            raise ValueError("Malformed provider checksum")
        sums.add(tuple(fields[:2]))
    missing = [
        f"{name} {version}{suffix}"
        for name, version in requirements
        for suffix in ("", "/go.mod")
        if (name, version + suffix) not in sums
    ]
    if missing:
        raise ValueError("Missing provider checksums: " + ", ".join(missing))
    return len(requirements)


def update_request(module, version, manifest):
    """Accept an exact module release and a new, disclosed derivative identity."""
    if not re.fullmatch(
        r"[A-Za-z0-9][A-Za-z0-9._~/-]+@v[0-9]+\.[0-9]+\.[0-9]+(?:[-+][A-Za-z0-9.+-]+)?",
        module,
    ):
        raise ValueError("Update requires an exact module@vX.Y.Z release")
    prefix = manifest["upstream_version"] + "-openssf."
    if not version.startswith(prefix) or not version[len(prefix) :].isdigit():
        raise ValueError("Update requires a new upstream-openssf.N build version")
    if int(version[len(prefix) :]) <= int(
        manifest["build_version"].removeprefix(prefix)
    ):
        raise ValueError("The derivative build version must increase")


def source_context():
    """Require a verified TLS chain with the strict OpenSSL 3 key policy."""
    if ssl.OPENSSL_VERSION_INFO[0] < 3:
        raise RuntimeError("Source downloads require OpenSSL 3 or newer")
    context = ssl.create_default_context()
    context.minimum_version = max(context.minimum_version, ssl.TLSVersion.TLSv1_2)
    level = max(3, context.security_level)
    ciphers = ":".join(
        item["name"] for item in context.get_ciphers() if item["protocol"] != "TLSv1.3"
    )
    context.set_ciphers(f"{ciphers}:@SECLEVEL={level}")
    if context.security_level < 3:
        raise RuntimeError("Unable to enforce the strict certificate key policy")
    return context


def validate_source_url(url):
    """Keep the unauthenticated pinned archive request on verified GitHub HTTPS."""
    parsed = urlsplit(url)
    if (
        parsed.scheme != "https"
        or parsed.hostname not in {"github.com", "codeload.github.com"}
        or parsed.username is not None
        or parsed.password is not None
        or parsed.port not in {None, 443}
    ):
        raise ValueError("Source downloads and redirects must use GitHub HTTPS")


class HTTPSOnlyRedirect(urllib.request.HTTPRedirectHandler):
    """Reject downgrade and off-origin redirects before a new request is sent."""

    def redirect_request(self, request, fp, code, msg, headers, newurl):
        validate_source_url(newurl)
        return super().redirect_request(request, fp, code, msg, headers, newurl)


def download_source(url, destination):
    """Use the same strict policy for the original request and every redirect."""
    validate_source_url(url)
    opener = urllib.request.build_opener(
        urllib.request.HTTPSHandler(context=source_context()), HTTPSOnlyRedirect()
    )
    with opener.open(url, timeout=60) as response:
        destination.write_bytes(response.read())


def extract_source(archive, destination):
    """Accept only regular files/directories below the extraction root."""
    with tarfile.open(archive, "r:gz") as bundle:
        for member in bundle.getmembers():
            target = (destination / member.name).resolve()
            if not target.is_relative_to(destination.resolve()):
                raise ValueError("Source archive escapes extraction root")
            if not (member.isfile() or member.isdir()):
                raise ValueError("Source archive contains links or special files")
        bundle.extractall(destination, filter="data")


def clean_environment(root, go):
    """Exclude cloud credentials, operator Go configuration and Terraform options."""
    return {
        "PATH": str(go.parent) + os.pathsep + os.environ.get("PATH", ""),
        "HOME": str(root),
        "TMPDIR": str(root / "tmp"),
        "GOTOOLCHAIN": "local",
        "GOENV": "off",
        "GOWORK": "off",
        "GOPROXY": "https://proxy.golang.org",
        "GOSUMDB": "sum.golang.org",
        "GOPATH": str(root / "gopath"),
        "GOCACHE": str(root / "cache"),
        "GOBIN": str(root / "bin"),
        "CGO_ENABLED": "0",
        "GOTELEMETRY": "off",
        "GOMAXPROCS": "2",
        "GODEBUG": "fips140=on",
    }


def run(command, source, environment, log):
    """Retain the complete result and stop on a failed qualification stage."""
    print("Running:", " ".join(map(str, command)), flush=True)
    with log.open("w", encoding="utf-8") as stream:
        subprocess.run(
            list(map(str, command)),
            cwd=source,
            env=environment,
            stdout=stream,
            stderr=subprocess.STDOUT,
            check=True,
        )


def main():
    """Build and qualify a pinned, explicitly labelled derivative provider."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--go", required=True, type=Path, help="Verified Go executable matching the snapshot manifest"
    )
    parser.add_argument(
        "--output", required=True, type=Path, help="New artifact directory"
    )
    parser.add_argument(
        "--platform",
        choices=("linux_amd64", "linux_arm64", "darwin_amd64", "darwin_arm64"),
        required=True,
    )
    parser.add_argument(
        "--update-module", help="Exact module@version, resolved in upstream source"
    )
    parser.add_argument(
        "--build-version", help="New disclosed derivative version for an update"
    )
    args = parser.parse_args()
    go = args.go.resolve(strict=True)
    output = args.output.resolve()
    if output.exists():
        raise SystemExit(
            "Output must be a new directory; existing artifacts are never overwritten"
        )
    pinned = Path(__file__).resolve().parents[1] / "security/provider"
    manifest = json.loads((pinned / "manifest.json").read_text())
    validate_snapshot(pinned, manifest)
    if bool(args.update_module) != bool(args.build_version):
        parser.error("--update-module and --build-version must be used together")
    if args.update_module:
        update_request(args.update_module, args.build_version, manifest)
    with tempfile.TemporaryDirectory(prefix="secure-provider-") as temporary:
        temporary = Path(temporary)
        (temporary / "tmp").mkdir()
        environment = clean_environment(temporary, go)
        actual = subprocess.check_output(
            [str(go), "env", "GOVERSION"], cwd=temporary, env=environment, text=True
        ).strip()
        if actual != manifest["go_version"]:
            raise SystemExit(
                f"Expected {manifest['go_version']}, found {actual}; do not infer compiler version from GOTOOLCHAIN"
            )
        output.mkdir(parents=True)
        archive = temporary / "source.tar.gz"
        download_source(manifest["source_url"], archive)
        if digest(archive) != manifest["source_sha256"]:
            raise SystemExit("Upstream source checksum mismatch")
        extract_source(archive, temporary)
        source = temporary / manifest["source_root"]
        for name in manifest["module_files"]:
            shutil.copyfile(pinned / name, source / name)
        shutil.copyfile(source / "LICENSE", output / "UPSTREAM-LICENSE")
        if args.update_module:
            run(
                [go, "get", args.update_module],
                source,
                environment,
                output / "update.log",
            )
        run([go, "mod", "download"], source, environment, output / "download.log")
        run([go, "mod", "verify"], source, environment, output / "modules.log")
        # A lock-only directory cannot prove that the actual provider can import
        # its dependencies. Include test imports and prohibit automatic repairs.
        run(
            [go, "list", "-mod=readonly", "-deps", "-test", "./..."],
            source,
            environment,
            output / "source-imports.log",
        )
        if args.update_module:
            manifest = {
                **manifest,
                "build_version": args.build_version,
                "module_files": {
                    name: digest(source / name) for name in manifest["module_files"]
                },
            }
        validate_snapshot(source, manifest)
        run(
            [
                go,
                "install",
                "golang.org/x/vuln/cmd/govulncheck@" + manifest["govulncheck_version"],
            ],
            source,
            environment,
            output / "scanner-install.log",
        )
        run(
            [temporary / "bin/govulncheck", "-show", "traces", "."],
            source,
            environment,
            output / "source-vulnerabilities.log",
        )
        run(
            [
                go,
                "test",
                "-mod=readonly",
                "-p",
                "2",
                "-short",
                "-skip",
                "^TestAcc",
                "./...",
            ],
            source,
            environment,
            output / "unit-tests.log",
        )
        binary = output / manifest["binary_name"]
        platform_os, platform_arch = args.platform.split("_")
        target_environment = {
            **environment,
            "GOOS": platform_os,
            "GOARCH": platform_arch,
        }
        run(
            [
                go,
                "build",
                "-p",
                "2",
                "-mod=readonly",
                "-trimpath",
                "-buildvcs=false",
                "-ldflags=-s -w -X main.version=" + manifest["build_version"],
                "-o",
                binary,
                ".",
            ],
            source,
            target_environment,
            output / "build.log",
        )
        run(
            [go, "version", "-m", binary],
            source,
            environment,
            output / "binary-metadata.log",
        )
        metadata = (output / "binary-metadata.log").read_text()
        if manifest["go_version"] not in metadata.splitlines()[0]:
            raise SystemExit("Built executable does not report the qualified compiler")
        for name, expected in manifest["module_files"].items():
            if digest(source / name) != expected:
                raise SystemExit(
                    f"Build unexpectedly changed pinned dependencies: {name}"
                )
        # Export an update only after every qualification stage passes. The
        # tracked snapshot and Terraform provider lock files are never edited.
        for name in manifest["module_files"]:
            shutil.copyfile(source / name, output / name)
        (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
        provenance = {
            **manifest,
            "platform": args.platform,
            "actual_go_version": actual,
            "binary_sha256": digest(binary),
            "qualification": "source scan and non-acceptance unit tests passed; transport calibration still required",
        }
        (output / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")
    print(
        f"Built disclosed derivative in {output}; not installed. Run the real TLS tests before use."
    )


if __name__ == "__main__":
    main()
