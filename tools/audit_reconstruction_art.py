#!/usr/bin/env python3
"""Check complete world/stage/view coverage and distinct encoded artwork."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
assets = ROOT / 'godot/assets/reconstruction'
manifest = json.loads((assets/'manifest.json').read_text())
entries = manifest['images']
ids = {int(entry['world']) for entry in entries}
expected = {(world, phase, view) for world in ids for phase in range(1, 5) for view in ('landing', 'orbital')}
actual = {(int(e['world']), int(e['phase']), e['view']) for e in entries}
assert len(ids) == 107 and len(entries) == 856 and actual == expected, 'Incomplete or duplicate world/stage/view coverage'
hashes = {}
for entry in entries:
    path = ROOT/'godot'/entry['file'].removeprefix('res://')
    data = path.read_bytes()
    assert data[:4] == b'RIFF' and data[8:12] == b'WEBP', f'Invalid WebP: {path}'
    digest = hashlib.sha256(data).hexdigest()
    assert digest not in hashes, f'Duplicate pictures: {path} and {hashes.get(digest)}'
    hashes[digest] = str(path.relative_to(ROOT))
print(f'RECONSTRUCTION ART: {len(ids)} worlds; {len(entries)} distinct pictures; complete 4-stage landing/orbital coverage')
