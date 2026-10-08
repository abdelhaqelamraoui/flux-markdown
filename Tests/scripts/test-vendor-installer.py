#!/usr/bin/env python3
"""Transaction tests use a signed local stub app; never register a real extension."""
import os, pathlib, plistlib, subprocess, tempfile, unittest
ROOT = pathlib.Path(__file__).resolve().parents[2]
class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='flux-installer-tests-')
        self.base = pathlib.Path(self.temp.name)
        self.apps = self.base/'Applications'; self.apps.mkdir()
        (self.apps/'untouched.txt').write_text('keep')
    def tearDown(self): self.temp.cleanup()
    def app(self, parent, marker, failure=False):
        app = parent/'FluxMarkdown.app'; contents=app/'Contents'; (contents/'MacOS').mkdir(parents=True)
        (contents/'Resources').mkdir()
        info={'CFBundleIdentifier':'com.xykong.Markdown','CFBundleExecutable':'FluxMarkdown','CFBundlePackageType':'APPL','CFBundleVersion':'1','CFBundleShortVersionString':'1.0.1'}
        (contents/'Info.plist').write_bytes(plistlib.dumps(info))
        (contents/'Resources'/'marker').write_text(marker)
        binary=contents/'MacOS'/'FluxMarkdown'
        binary.write_text('#!/bin/bash\ncase "$1" in\n--default-md-state) printf \'%s\' \'{"net.daringfireball.markdown":"com.example.Editor"}\';;\n--repair-quicklook) printf \'%s\\n\' "$*" > "$FLUX_TEST_RECEIPT"; exit '+('42' if failure else '0')+';;\n*) exit 2;;\nesac\n')
        binary.chmod(0o755)
        subprocess.run(['/usr/bin/codesign','--force','--sign','-',str(app)],check=True,capture_output=True)
        return app
    def invoke(self, source):
        env=dict(os.environ,FLUX_TEST_RECEIPT=str(self.base/'receipt'))
        return subprocess.run(['/bin/bash',str(ROOT/'scripts/install-flux-markdown.sh'),'--source',str(source),'--appdir',str(self.apps)],env=env,capture_output=True,text=True)
    def test_success_and_reinstall_preserve_editor_and_other_files(self):
        source=self.app(self.base/'source','new')
        for _ in range(2): self.assertEqual(self.invoke(source).returncode,0)
        self.assertEqual((self.apps/'FluxMarkdown.app/Contents/Resources/marker').read_text(),'new')
        self.assertIn('com.example.Editor',(self.base/'receipt').read_text())
        self.assertEqual((self.apps/'untouched.txt').read_text(),'keep')
    def test_registration_failure_restores_existing_application(self):
        self.app(self.apps,'old')
        source=self.app(self.base/'source','new',True)
        self.assertNotEqual(self.invoke(source).returncode,0)
        self.assertEqual((self.apps/'FluxMarkdown.app/Contents/Resources/marker').read_text(),'old')
        self.assertEqual((self.apps/'untouched.txt').read_text(),'keep')
    def test_failed_fresh_install_leaves_no_application(self):
        source=self.app(self.base/'source','new',True)
        self.assertNotEqual(self.invoke(source).returncode,0)
        self.assertFalse((self.apps/'FluxMarkdown.app').exists())
    def test_invalid_source_cannot_replace_existing_application(self):
        self.app(self.apps,'old')
        self.assertNotEqual(self.invoke(self.base/'missing.app').returncode,0)
        self.assertEqual((self.apps/'FluxMarkdown.app/Contents/Resources/marker').read_text(),'old')
if __name__ == '__main__': unittest.main()
