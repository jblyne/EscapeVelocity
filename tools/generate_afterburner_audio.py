"""Generate a quiet, seamless tonal afterburner rumble (no wind sample)."""
import math, struct, wave
from pathlib import Path
rate=22050
samples=[]
for i in range(rate*2):
 t=i/rate
 pulse=0.88+0.12*math.sin(math.tau*7*t)
 value=pulse*(.24*math.sin(math.tau*55*t)+.11*math.sin(math.tau*110*t)+.055*math.sin(math.tau*165*t)+.025*math.sin(math.tau*330*t))
 samples.append(int(value*32767))
with wave.open(str(Path(__file__).resolve().parents[1]/'godot/audio/afterburner.wav'),'wb') as f:
 f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(struct.pack('<%dh'%len(samples),*samples))
