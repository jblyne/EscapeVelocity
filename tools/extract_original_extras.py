"""Recover original title extras verbatim from the user's 1.0.5 resources."""
from pathlib import Path
import json, wave
from inspect_ev import read_resources, decode_strings
from extract_title_art import decode
from extract_special_effects import pcm_sound
root=Path(__file__).resolve().parents[1]
source=root/'research/extracted'
records=read_resources(next(source.rglob('Escape Velocity.rsrc')).read_bytes())
credits={str(r['id']):decode_strings(r['data']) for r in records if r['type']=='STR#' and r['id'] in (20001,20002,20003)}
(root/'godot/data/original_extras.json').write_text(json.dumps(credits,ensure_ascii=False,indent=2))
for r in read_resources(next(source.rglob('EV Titles.rsrc')).read_bytes()):
    if r['type']=='PICT' and r['id']==8011: decode(r['data']).save(root/'godot/assets/classic/8011.png')
for r in read_resources(next(source.rglob('EV Sounds.rsrc')).read_bytes()):
    if r['type']=='snd ' and r['id']==3000:
        pcm,rate=pcm_sound(r['data'])
        with wave.open(str(root/'godot/audio/forklift_song.wav'),'wb') as out:
            out.setnchannels(1);out.setsampwidth(1);out.setframerate(rate);out.writeframes(pcm)
