"""Import the saved ElevenLabs performances into game WAV assets.
No service calls or voice synthesis; preserves pitch and timing. Originals and
prompts are retained in research/audio/elevenlabs/manifest.json.
"""
from pathlib import Path
import array
import json
import subprocess
import tempfile
import wave
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'research/audio/elevenlabs'

def generate(prefix=''):
    with tempfile.TemporaryDirectory(prefix='ev-panic-') as temp:
        for entry in json.loads((SOURCE / 'manifest.json').read_text()):
            if entry.get('archived'): continue
            if not entry['file'].startswith(prefix): continue
            converted = Path(temp) / 'voice.wav'
            subprocess.run(['afconvert', '-f', 'WAVE', '-d', 'LEI16@44100', '-c', '1', str(SOURCE / entry['file']), str(converted)], check=True)
            with wave.open(str(converted), 'rb') as inp:
                samples = array.array('h', inp.readframes(inp.getnframes()))
            voiced = [i for i, value in enumerate(samples) if abs(value) > 180]
            if not voiced: raise ValueError('Empty performance: '+entry['file'])
            samples = samples[max(0, voiced[0]-882):min(len(samples), voiced[-1]+2646)]
            peak = max(abs(v) for v in samples)
            gain = min(2.0, 26000 / peak)
            samples = array.array('h', (int(v * gain) for v in samples))
            if entry.get('death_fade'):
                length = min(len(samples), int(.85 * 44100))
                samples = samples[-length:] if entry.get('tail') else samples[:length]
                # Brief onset, then a smooth fall to silence; the WAV envelope
                # pauses naturally with the audio player and needs no timer.
                for i in range(length):
                    t = i / max(1, length - 1)
                    fade = max(0.0, min(1.0, (1.0 - t) / .85)) ** 2
                    attack = min(1.0, i / 220)
                    samples[i] = int(samples[i] * fade * attack)
            dest = ROOT / 'godot/audio' / entry.get('output', str(Path(entry['file']).with_suffix('.wav')))
            with wave.open(str(dest), 'wb') as out:
                out.setnchannels(1); out.setsampwidth(2); out.setframerate(44100)
                out.writeframes(samples.tobytes())
            print(f'{dest.name}: {entry["voice"]}, {len(samples)/44100:.2f}s')
if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prefix', default='', help='Import only matching asset names')
    generate(parser.parse_args().prefix)
