"""Preserve original weapon PCM: weapon Sound + 200 is its snd resource ID."""
from pathlib import Path
import json
import wave
from inspect_ev import read_resources
from extract_special_effects import pcm_sound
ROOT=Path(__file__).resolve().parents[1]
def extract():
    records=json.loads((ROOT/'research/decoded/decoded.json').read_text())['EV Data.rsrc']
    sounds={200+int(r['fields']['Sound']) for r in records if r['type']=='wëap' and int(r['fields']['Sound'])>=0}
    source=next((ROOT/'research/extracted').rglob('EV Sounds.rsrc'))
    recovered={r['id']:r for r in read_resources(source.read_bytes()) if r['type']=='snd '}
    for sound in sorted(sounds):
        r=recovered[sound];pcm,rate=pcm_sound(r['data'])
        path=ROOT/'godot/audio'/f'weapon_{sound}.wav'
        with wave.open(str(path),'wb') as out:
            out.setnchannels(1);out.setsampwidth(1);out.setframerate(rate);out.writeframes(pcm)
        print(sound,r['name'],len(pcm),rate)
if __name__=='__main__': extract()
