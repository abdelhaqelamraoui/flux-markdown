"""Publication failure/retry tests; all external commands are isolated stubs."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]

class PublicationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / 'scripts').mkdir()
        (self.root / 'bin').mkdir()
        (self.root / 'build/artifacts').mkdir(parents=True)
        shutil.copy(ROOT / 'scripts/publish-release.sh', self.root / 'scripts/publish-release.sh')
        for file, text in {'.version': '1.0.1', 'release_notes_tmp.md': 'notes', 'appcast.xml': 'feed',
                           'build/artifacts/FluxMarkdown.dmg': 'dmg',
                           'build/artifacts/FluxMarkdown-1.0.1-macports-source.tar.gz': 'tar'}.items():
            (self.root / file).write_text(text)
        (self.root / 'scripts/release-manifest.py').write_text('pass\n')
        for script in ['verify-release-entitlements.sh', 'generate-appcast.sh', 'update-homebrew-cask.sh']:
            self.write_script('scripts/' + script, 'exit 0')
        self.write_script('bin/git', 'if [[ "$*" == "diff --cached --quiet" ]]; then exit 1; fi\nif [[ "$*" == push* && "${FAIL_PUSH:-}" == 1 ]]; then exit 1; fi\nexit 0')
        self.write_script('bin/gh', '''echo "$*" >> gh.log
case "$*" in
  "release view"*) test -f published;;
  "release create"*) touch published;;
  "release download"*)
    while [ "$#" -gt 0 ]; do
      case "$1" in --dir) dest=$2; shift;; --pattern) asset=$2; shift;; esac
      shift
    done
    cp "build/artifacts/$asset" "$dest/$asset";;
  *) exit 0;;
esac''')
        self.env = dict(os.environ, PATH=str(self.root / 'bin') + ':' + os.environ['PATH'])
    def write_script(self, path, text):
        target = self.root / path
        target.write_text('#!/bin/bash\nset -e\n' + text + '\n')
        target.chmod(0o755)
    def run_publish(self):
        return subprocess.run(['bash', 'scripts/publish-release.sh'], cwd=self.root, env=self.env, capture_output=True, text=True)
    def test_preflight_failure_does_not_publish(self):
        self.write_script('scripts/generate-appcast.sh', 'exit 1')
        result = self.run_publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / 'published').exists())
    def test_retry_checks_existing_assets_without_creating_release(self):
        (self.root / 'published').touch()
        result = self.run_publish()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn('release create', (self.root / 'gh.log').read_text())
        self.assertTrue((self.root / 'release_notes_tmp.md').exists())
    def test_feed_push_failure_is_not_success(self):
        self.env['FAIL_PUSH'] = '1'
        result = self.run_publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('sparkle', result.stderr.lower())
    def test_homebrew_failure_is_not_success(self):
        self.write_script('scripts/update-homebrew-cask.sh', 'exit 2')
        result = self.run_publish()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('homebrew', result.stderr.lower())

    def test_existing_tag_is_rejected_before_version_changes(self):
        shutil.copy(ROOT / 'scripts/release.sh', self.root / 'scripts/release.sh')
        self.write_script('bin/git', '\n'.join([
            'case "$*" in',
            '"branch --show-current") echo master;;',
            '"status --porcelain --untracked-files=no") ;;',
            '"rev-list --count HEAD") echo 1;;',
            '"rev-parse --verify refs/tags/v1.0.1") exit 0;;',
            '*) exit 0;;', 'esac']))
        result = subprocess.run(['bash', 'scripts/release.sh'], cwd=self.root, env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.root / '.version').read_text(), '1.0.1')
        self.assertIn('--resume', result.stderr)

if __name__ == '__main__': unittest.main()
