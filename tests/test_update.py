"""Run update.sh on isolated Cask fixtures with a fake gh; no network access."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class UpdateTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        shutil.copy2(Path(__file__).resolve().parents[1] / "update.sh", self.root / "update.sh")
        (self.root / "Casks").mkdir()
        self.cask = self.root / "Casks/kleantalk.rb"
        self.cask.write_text('cask "kleantalk" do\n  version "1.0.0"\n  sha256 "old"\nend\n')
        self.initial = self.cask.read_text()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        gh = self.bin / "gh"
        gh.write_text('''#!/usr/bin/env python3
import os, pathlib, sys
if sys.argv[1:3] == ['release', 'view']:
    if os.environ.get('FAIL_VIEW'): sys.exit(1)
    print(os.environ.get('RELEASE_TAG', 'v2.0.0'))
elif sys.argv[1:3] == ['release', 'download']:
    if os.environ.get('FAIL_DOWNLOAD'): sys.exit(1)
    (pathlib.Path(sys.argv[sys.argv.index('--dir')+1]) / 'KleanTalk.dmg').write_bytes(b'fixture-only')
else:
    sys.exit(99)
''')
        gh.chmod(0o755)

    def run_update(self, *args, **extra):
        env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'], **extra)
        return subprocess.run(['zsh', str(self.root / 'update.sh'), *args], env=env,
                              capture_output=True, text=True)

    def test_check_outdated_is_read_only(self):
        result = self.run_update('--check', FAIL_DOWNLOAD='1')
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(self.cask.read_text(), self.initial)

    def test_check_current_succeeds(self):
        result = self.run_update('--check', RELEASE_TAG='v1.0.0')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.cask.read_text(), self.initial)

    def test_update_replaces_version_and_checksum(self):
        result = self.run_update()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('version "2.0.0"', self.cask.read_text())
        self.assertIn(hashlib.sha256(b'fixture-only').hexdigest(), self.cask.read_text())

    def test_release_lookup_failure_is_not_outdated(self):
        result = self.run_update('--check', FAIL_VIEW='1')
        self.assertGreaterEqual(result.returncode, 2)
        self.assertEqual(self.cask.read_text(), self.initial)

    def test_download_failure_leaves_cask_unchanged(self):
        result = self.run_update(FAIL_DOWNLOAD='1')
        self.assertGreaterEqual(result.returncode, 2)
        self.assertEqual(self.cask.read_text(), self.initial)

    def test_silent_sed_noop_is_detected(self):
        sed = self.bin / 'sed'
        sed.write_text('#!/bin/sh\nexit 0\n')
        sed.chmod(0o755)
        result = self.run_update()
        self.assertGreaterEqual(result.returncode, 2)
        self.assertIn('verification failed', result.stderr)

    def test_invalid_release_tag_is_rejected(self):
        result = self.run_update(RELEASE_TAG='v2.0.0/bad')
        self.assertGreaterEqual(result.returncode, 2)
        self.assertEqual(self.cask.read_text(), self.initial)


if __name__ == '__main__':
    unittest.main()
