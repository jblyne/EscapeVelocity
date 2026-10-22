"""Extract the actual Sillycon Plain TrueType font from EV 1.0.5."""
from pathlib import Path
from inspect_ev import read_resources
source = next(Path('research/extracted').rglob('Escape Velocity.rsrc'))
font = next(r for r in read_resources(source.read_bytes()) if r['type'] == 'sfnt' and r['id'] == 9295)
Path('godot/assets/fonts/EVOriginal.ttf').write_bytes(font['data'])
