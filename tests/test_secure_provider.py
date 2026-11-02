"""Security boundaries of the opt-in provider build, without network access."""

import importlib.util
import io
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "secure_provider", Path(__file__).parents[1] / "scripts/build_secure_provider.py"
)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
SCOPE_SPEC = importlib.util.spec_from_file_location(
    "provider_scope", Path(__file__).parents[1] / "scripts/check_provider_snapshot.py"
)
SCOPE = importlib.util.module_from_spec(SCOPE_SPEC)
with patch.dict(sys.modules, {"build_secure_provider": MODULE}):
    SCOPE_SPEC.loader.exec_module(SCOPE)


class ProviderSnapshotTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        pinned = Path(__file__).parents[1] / "security/provider"
        for name in ("go.mod", "go.sum", "manifest.json"):
            shutil.copyfile(pinned / name, self.root / name)
        self.manifest = json.loads((self.root / "manifest.json").read_text())

    def refresh_hashes(self):
        self.manifest["module_files"] = {
            name: MODULE.digest(self.root / name) for name in ("go.mod", "go.sum")
        }

    def test_current_snapshot_contains_actual_requirements(self):
        self.assertGreater(MODULE.validate_snapshot(self.root, self.manifest), 0)

    def test_dependabot_empty_graph_fails_even_with_refreshed_hashes(self):
        (self.root / "go.mod").write_text(
            "module github.com/integrations/terraform-provider-github/v6\n\ngo 1.26.0\n"
        )
        (self.root / "go.sum").write_text("")
        self.refresh_hashes()
        with self.assertRaisesRegex(ValueError, "requirements are empty"):
            MODULE.validate_snapshot(self.root, self.manifest)

    def test_empty_sums_and_missing_one_archive_checksum_fail(self):
        original = (self.root / "go.sum").read_text()
        for contents in (
            "",
            "\n".join(
                line
                for line in original.splitlines()
                if not line.startswith("github.com/go-jose/go-jose/v4 v")
                or "/go.mod " in line
            )
            + "\n",
        ):
            with self.subTest(contents_length=len(contents)):
                (self.root / "go.sum").write_text(contents)
                self.refresh_hashes()
                with self.assertRaisesRegex(ValueError, "Missing provider checksums"):
                    MODULE.validate_snapshot(self.root, self.manifest)

    def test_stale_manifest_hash_fails_before_using_dependencies(self):
        with (self.root / "go.mod").open("a") as stream:
            stream.write("\n")
        with self.assertRaisesRegex(ValueError, "checksum mismatch"):
            MODULE.validate_snapshot(self.root, self.manifest)

    def test_update_requires_an_exact_version_and_new_derivative_identity(self):
        old = self.manifest["build_version"]
        prefix, revision = old.rsplit(".", 1)
        new = prefix + "." + str(int(revision) + 1)
        MODULE.update_request(
            "github.com/go-jose/go-jose/v4@v4.1.6", new, self.manifest
        )
        for module, version in (
            ("example.com/mod@latest", new),
            ("-flag@v1.2.3", new),
            ("example.com/mod@v1.2.3", old),
        ):
            with (
                self.subTest(module=module, version=version),
                self.assertRaises(ValueError),
            ):
                MODULE.update_request(module, version, self.manifest)


class ProviderScopeTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.git("init", "-q")
        (self.root / "README.md").write_text("readme\n")
        (self.root / "security/provider").mkdir(parents=True)
        (self.root / "security/provider/go.mod").write_text(
            "module example.com/module\n"
        )
        self.base = self.commit()

    def git(self, *args):
        return (
            subprocess.check_output(
                [
                    "git",
                    "-c",
                    "user.name=Fixture",
                    "-c",
                    "user.email=fixture@example.invalid",
                    "-c",
                    "commit.gpgsign=false",
                    *args,
                ],
                cwd=self.root,
                stderr=subprocess.DEVNULL,
            )
            .decode()
            .strip()
        )

    def commit(self):
        self.git("add", "-A")
        self.git("commit", "-qm", "fixture")
        return self.git("rev-parse", "HEAD")

    def event(self, head):
        return {"pull_request": {"base": {"sha": self.base}, "head": {"sha": head}}}

    def test_unrelated_complete_diff_skips_only_expensive_build(self):
        (self.root / "README.md").write_text("new readme\n")
        self.assertFalse(
            SCOPE.qualification_required(
                self.root, "pull_request", self.event(self.commit())
            )
        )

    def test_rename_out_of_provider_directory_still_requires_build(self):
        (self.root / "security/provider/go.mod").rename(self.root / "moved.txt")
        self.assertTrue(
            SCOPE.qualification_required(
                self.root, "pull_request", self.event(self.commit())
            )
        )

    def test_changes_to_builder_workflow_or_snapshot_require_build(self):
        for path in (
            "scripts/build_secure_provider.py",
            "security/provider/go.sum",
            ".github/workflows/validate.yml",
            "tests/test_secure_provider.py",
        ):
            with self.subTest(path=path):
                self.assertTrue(SCOPE.relevant(path))

    def test_unknown_events_invalid_or_missing_history_never_skip(self):
        self.assertTrue(SCOPE.qualification_required(self.root, "schedule", {}))
        self.assertTrue(SCOPE.qualification_required(self.root, "pull_request", None))
        self.assertTrue(
            SCOPE.qualification_required(
                self.root, "push", {"before": "0" * 40, "after": self.base}
            )
        )
        self.assertTrue(
            SCOPE.qualification_required(
                self.root, "push", {"before": self.base, "after": self.base}
            )
        )

    def test_merge_group_and_push_use_their_full_diff(self):
        (self.root / "security/provider/go.mod").write_text(
            "module example.com/updated\n"
        )
        head = self.commit()
        self.assertTrue(
            SCOPE.qualification_required(
                self.root, "push", {"before": self.base, "after": head}
            )
        )
        self.assertTrue(
            SCOPE.qualification_required(
                self.root,
                "merge_group",
                {
                    "merge_group": {"base_sha": self.base, "head_sha": head},
                },
            )
        )


class SecureProviderBuildTests(unittest.TestCase):
    def test_archive_cannot_escape_or_create_links(self):
        for name, kind in [
            ("../escape", tarfile.REGTYPE),
            ("/escape", tarfile.REGTYPE),
            ("source/link", tarfile.SYMTYPE),
            ("source/link", tarfile.LNKTYPE),
        ]:
            with (
                self.subTest(name=name, kind=kind),
                tempfile.TemporaryDirectory() as directory,
            ):
                root = Path(directory)
                archive = root / "source.tar.gz"
                with tarfile.open(archive, "w:gz") as bundle:
                    entry = tarfile.TarInfo(name)
                    entry.type = kind
                    entry.linkname = "/outside"
                    bundle.addfile(entry)
                with self.assertRaises(ValueError):
                    MODULE.extract_source(archive, root / "extracted")
                self.assertFalse((root / "extracted").exists())

    def test_regular_source_archive_is_supported(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            archive = root / "source.tar.gz"
            with tarfile.open(archive, "w:gz") as bundle:
                content = b"synthetic source"
                entry = tarfile.TarInfo("source/main.go")
                entry.size = len(content)
                bundle.addfile(entry, io.BytesIO(content))
            MODULE.extract_source(archive, root / "extracted")
            self.assertEqual((root / "extracted/source/main.go").read_bytes(), content)

    def test_build_cannot_inherit_operator_credentials_or_compiler_overrides(self):
        private = {
            "GITHUB_TOKEN": "private",
            "GH_TOKEN": "private",
            "AWS_ACCESS_KEY_ID": "private",
            "TF_CLI_CONFIG_FILE": "/private/config",
            "TF_REATTACH_PROVIDERS": "private",
            "GOPRIVATE": "*",
            "GOINSECURE": "*",
            "GOFLAGS": "-modfile=/private/go.mod",
            "GOROOT": "/unverified/compiler",
        }
        with patch.dict(os.environ, private):
            environment = MODULE.clean_environment(
                Path("/temporary"), Path("/verified/bin/go")
            )
        self.assertFalse(set(private) & set(environment))
        self.assertEqual(environment["GOTOOLCHAIN"], "local")
        self.assertEqual(environment["GOENV"], "off")
        self.assertEqual(environment["GOWORK"], "off")
        self.assertEqual(environment["GOSUMDB"], "sum.golang.org")
        self.assertEqual(environment["PATH"].split(os.pathsep)[0], "/verified/bin")


if __name__ == "__main__":
    unittest.main()
