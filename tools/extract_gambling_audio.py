"""Recover the original EV slot-machine reel samples without resampling."""
from pathlib import Path
import wave
from inspect_ev import read_resources
from extract_special_effects import pcm_sound
ROOT = Path(__file__).resolve().parents[1]
SOUNDS = {460: 'slot_flip', 461: 'slot_lock'}
def extract():
    source = next((ROOT/'research/extracted').rglob('EV Sounds.rsrc'))
    for record in read_resources(source.read_bytes()):
        if record['type'] != 'snd ' or record['id'] not in SOUNDS:
            continue
        pcm, rate = pcm_sound(record['data'])
        name = SOUNDS[record['id']]
        with wave.open(str(ROOT/'godot/audio'/f'{name}.wav'), 'wb') as output:
            output.setnchannels(1)
            output.setsampwidth(1)
            output.setframerate(rate)
            output.writeframes(pcm)
        print(record['id'], name, len(pcm), rate)
if __name__ == '__main__':
    extract()
