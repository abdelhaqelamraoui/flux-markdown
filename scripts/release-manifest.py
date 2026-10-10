#!/usr/bin/env python3
"""Bind publication to the exact prepared tag, notes and package bytes."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

version = Path('.version').read_text().strip()
tag = 'v' + version
commit = subprocess.check_output(['git', 'rev-parse', tag + '^{commit}'], text=True).strip()
subprocess.run(['git', 'merge-base', '--is-ancestor', commit, 'HEAD'], check=True)
assert subprocess.check_output(['git', 'show', tag + ':.version'], text=True).strip() == version
paths = ['build/artifacts/FluxMarkdown.dmg',
         f'build/artifacts/FluxMarkdown-{version}-macports-source.tar.gz',
         'release_notes_tmp.md']
manifest = {'version': version, 'commit': commit,
            'sha256': {path: hashlib.sha256(Path(path).read_bytes()).hexdigest() for path in paths}}
record = Path('build/artifacts/release-manifest.json')
if sys.argv[1:] == ['write']:
    record.write_text(json.dumps(manifest, indent=2) + '\n')
elif sys.argv[1:] == ['verify']:
    if json.loads(record.read_text()) != manifest:
        sys.exit('Prepared release changed: refusing publication')
else:
    sys.exit('Usage: release-manifest.py write|verify')
