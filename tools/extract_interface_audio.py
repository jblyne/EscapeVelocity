"""Preserve original interface and boarding PCM from EV Sounds.rsrc."""
from pathlib import Path
import wave
from inspect_ev import read_resources
from extract_special_effects import pcm_sound
ROOT=Path(__file__).resolve().parents[1]
SOUNDS={128:'jump_start',130:'arrival',150:'ui_target',151:'ui_open',152:'ui_select',153:'ui_error',154:'ui_confirm',390:'airlock'}
def extract():
    source=next((ROOT/'research/extracted').rglob('EV Sounds.rsrc'))
    for record in read_resources(source.read_bytes()):
        if record['type']!='snd ' or record['id'] not in SOUNDS: continue
        pcm,rate=pcm_sound(record['data'])
        with wave.open(str(ROOT/'godot/audio'/f'{SOUNDS[record["id"]]}.wav'),'wb') as out:
            out.setnchannels(1);out.setsampwidth(1);out.setframerate(rate);out.writeframes(pcm)
        print(record['id'],SOUNDS[record['id']],len(pcm),rate)
if __name__=='__main__': extract()
