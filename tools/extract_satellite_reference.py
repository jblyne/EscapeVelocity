"""Recover original secret shipyard illustration, PICT 5200.
The native macOS PICT decoder supports its DirectBitsRect data.
"""
from pathlib import Path
import subprocess
from inspect_ev import read_resources
ROOT=Path(__file__).resolve().parents[1]
if __name__=='__main__':
    source=next((ROOT/'research/extracted').rglob('EV Graphics.rsrc'))
    r=next(r for r in read_resources(source.read_bytes()) if r['type']=='PICT' and r['id']==5200)
    temporary=Path('/tmp/ev-satellite.pict');temporary.write_bytes(bytes(512)+r['data'])
    subprocess.run(['sips','-s','format','png',str(temporary),'--out',str(ROOT/'godot/assets/classic/5200.png')],check=True)
