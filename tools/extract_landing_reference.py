"""Recover original landscape references for art direction, without changing assets."""
from pathlib import Path
from inspect_ev import read_resources
from extract_title_art import decode

ROOT = Path(__file__).resolve().parents[1]

def extract():
    out = ROOT / 'research/decoded/landing-reference'
    out.mkdir(parents=True, exist_ok=True)
    for filename in ['EV Titles.rsrc', 'EV Graphics.rsrc']:
        source = next((ROOT / 'research/extracted').rglob(filename))
        for item in read_resources(source.read_bytes()):
            if item['type'] != 'PICT':
                continue
            rid = item['id']
            if (filename == 'EV Titles.rsrc' and (10000 <= rid <= 10033 or rid == 11000)) or (filename == 'EV Graphics.rsrc' and rid == 11001):
                decode(item['data']).save(out / f'{rid}.png')
    print('Extracted 34 type landscapes and two custom landing pictures.')

if __name__ == '__main__':
    extract()
