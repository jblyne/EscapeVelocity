"""Recover EV 1.0.5's original application icon and its transparency mask."""
from pathlib import Path
from itertools import product
from PIL import Image
from inspect_ev import read_resources

source=next(Path('research/extracted').rglob('Escape Velocity.rsrc'))
resources={(r['type'],r['id']):r['data'] for r in read_resources(source.read_bytes())}
# Standard Macintosh 8-bit system palette: cube, four ramps, black.
colors=list(product([255,204,153,102,51,0],repeat=3))[:-1]
for channel in range(4):
    for level in [238,221,187,170,136,119,85,68,34,17]:
        colors.append(tuple(level if channel==3 or i==channel else 0 for i in range(3)))
colors.append((0,0,0))
data=resources['icl8',128];mask=resources['ICN#',128][128:]
icon=Image.new('RGBA',(32,32))
icon.putdata([(*colors[value],255 if mask[i//8]&(128>>(i%8)) else 0) for i,value in enumerate(data)])
output=Path('godot/assets/icon');output.mkdir(exist_ok=True)
icon.save(output/'original-32.png')
icon.resize((1024,1024),Image.Resampling.NEAREST).save(output/'app-icon.png')
preview=Path('/tmp/ev-original-app-icon.png');icon.resize((384,384),Image.Resampling.NEAREST).save(preview)
print(preview)
