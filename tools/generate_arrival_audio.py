"""Synthesize an original stereo thunderclap for hyperspace arrival."""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 44100
DURATION = 3.2
OUTPUT = Path(__file__).resolve().parents[1] / "godot/audio/arrival.wav"


def generate(destination=OUTPUT):
    rng = random.Random(2276)
    count = round(RATE * DURATION)
    dry = []
    bass = sub = mid = air = 0.0
    coefficients = [1 - math.exp(-2 * math.pi * hz / RATE) for hz in (145, 55, 1800, 5000)]
    for i in range(count):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        bass += coefficients[0] * (noise - bass)
        sub += coefficients[1] * (noise - sub)
        mid += coefficients[2] * (noise - mid)
        air += coefficients[3] * (noise - air)
        # Immediate crack, dense low impact, then irregular rolling thunder.
        crack = (air - mid) * 2.8 * math.exp(-t / 0.035)
        body = (mid - bass) * 1.8 * math.exp(-t / 0.16)
        roll = 0.75 + 0.16 * math.sin(t * 13.7) + 0.09 * math.sin(t * 31.3)
        rumble = (bass * 3.2 + sub * 5.5) * math.exp(-t / 0.75) * roll
        boom = math.sin(2 * math.pi * (48 * t - 3 * t * t)) * 0.32 * math.exp(-t / 0.22)
        attack = min(1.0, t / 0.0015)
        dry.append((crack + body + rumble + boom) * attack)

    # Short, asymmetric reflections give the crack width without delaying onset.
    reflections = [(0.019, 0.25, 0.17), (0.047, 0.18, 0.26),
                   (0.091, 0.16, 0.10), (0.157, 0.09, 0.15),
                   (0.263, 0.07, 0.10), (0.419, 0.05, 0.04)]
    stereo = []
    for i in range(count):
        left = right = dry[i]
        for delay, l_gain, r_gain in reflections:
            source = i - round(delay * RATE)
            if source >= 0:
                left += dry[source] * l_gain
                right += dry[source] * r_gain
        fade = min(1.0, (count - 1 - i) / (RATE * 0.35))
        stereo.append((left * fade, right * fade))
    dc_left = sum(pair[0] for pair in stereo) / count
    dc_right = sum(pair[1] for pair in stereo) / count
    peak = max(max(abs(l - dc_left), abs(r - dc_right)) for l, r in stereo)
    gain = 0.90 / peak
    frames = bytearray()
    for i, (left, right) in enumerate(stereo):
        # Keep both endpoints at zero after DC removal to prevent playback clicks.
        edge = min(1.0, i / (RATE * 0.0005), (count - 1 - i) / (RATE * 0.01))
        frames.extend(struct.pack("<hh", round((left - dc_left) * gain * edge * 32767),
                                  round((right - dc_right) * gain * edge * 32767)))
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(destination), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(frames)
    print(f"Generated {destination.name}: stereo, {RATE} Hz, {DURATION:.1f}s thunderclap")


if __name__ == "__main__":
    generate()
