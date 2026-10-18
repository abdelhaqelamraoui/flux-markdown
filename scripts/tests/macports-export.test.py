#!/usr/bin/env python3
"""Exercise the real export transforms and parse their output with XcodeGen."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class MacPortsExportTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which("xcodegen"), "XcodeGen is needed to validate exported projects")
    def test_removing_sparkle_leaves_a_valid_project_and_no_updater_references(self):
        script = (ROOT / "scripts/create_macports_tarball.sh").read_text()
        project = (ROOT / "project.yml").read_text()
        with tempfile.TemporaryDirectory() as directory:
            stage = Path(directory)
            (stage / "project.yml").write_text(project)
            paths = re.findall(r"^\s+- (Sources/[^\s]+|Tests/[^\s]+|benchmark/[^\s]+)", project, re.MULTILINE)
            for name in paths:
                path = stage / name
                if path.suffix == ".swift":
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text("// Fixture\n")
                else:
                    path.mkdir(parents=True, exist_ok=True)
                    (path / "Fixture.swift").write_text("// Fixture\n")
            (stage / "web-renderer/dist").mkdir(parents=True)
            (stage / "web-renderer/dist/index.html").write_text("<html></html>")
            for name in ["MarkdownApp.swift", "UpdateDelegate.swift", "AppUpdaterController.swift"]:
                shutil.copyfile(ROOT / "Sources/Markdown" / name, stage / "Sources/Markdown" / name)
            for argument, target in [("\"$STAGING_DIR/project.yml\"", stage / "project.yml"), ("\"$STAGING_DIR\"", stage)]:
                pattern = r"python3 - " + re.escape(argument) + r" <<'PYEOF'\n(.*?)\nPYEOF"
                block = re.findall(pattern, script, re.DOTALL)[0]
                subprocess.run(["python3", "-", str(target)], input=block, text=True, check=True, capture_output=True)
            app = (stage / "Sources/Markdown/MarkdownApp.swift").read_text()
            self.assertNotIn("updaterController", app)
            self.assertNotIn("import Sparkle", app)
            env = dict(os.environ, MARKETING_VERSION="1.0.1", CURRENT_PROJECT_VERSION="1")
            result = subprocess.run(["xcodegen", "generate", "--quiet", "--spec", str(stage / "project.yml"), "--project", str(stage)], env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            generated = (stage / "FluxMarkdown.xcodeproj/project.pbxproj").read_text()
            self.assertNotIn("XCSwiftPackageProductDependency", generated)


if __name__ == "__main__":
    unittest.main()
