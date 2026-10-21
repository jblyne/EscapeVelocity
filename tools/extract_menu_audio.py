"""Recover the original EV menu recordings without synthesis or resampling.

Source unsigned 8-bit PCM is preserved. WAV's integer sample rate rounds the
original Sound Manager 16.16 rate by less than half a Hertz. Source headers have
no valid looping regions for these recordings; they are exported as one-shots.
"""
from pathlib import Path
import wave
from inspect_ev import read_resources
from extract_special_effects import pcm_sound

ROOT=Path(__file__).resolve().parents[1]
SOURCES={"EV Sounds.rsrc":{600:"menu_click",601:"menu_hum",602:"menu_slam"},
         "EV Music.rsrc":{30000:"menu_music",30001:"intro_drums",30002:"intro_drum_loop",30003:"intro_transition"}}

def extract():
    for fork,names in SOURCES.items():
        source=next((ROOT/"research/extracted").rglob(fork))
        for record in read_resources(source.read_bytes()):
            if record["type"]!="snd " or record["id"] not in names:
                continue
            pcm,rate=pcm_sound(record["data"])
            path=ROOT/"godot/audio"/(names[record["id"]]+".wav")
            with wave.open(str(path),"wb") as out:
                out.setnchannels(1);out.setsampwidth(1);out.setframerate(rate);out.writeframes(pcm)
            print(f'{path.name}: {record["name"]}, snd {record["id"]}, {len(pcm)} samples, {rate} Hz')

if __name__=="__main__":
    extract()
