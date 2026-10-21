"""Generate original synthesized placeholder audio. No original audio is copied."""
from pathlib import Path
import math, random, struct, wave
ROOT=Path(__file__).resolve().parents[1]/'godot/audio'
ROOT.mkdir(exist_ok=True)
RATE=22050
rng=random.Random(1996)
for name,duration in [('laser',0.18),('impact',0.22),('explosion',0.9),('jump',2.4),('land',0.7),('engine',1.0)]:
    samples=[]; phase=0; low=0
    for i in range(int(RATE*duration)):
        t=i/RATE; u=t/duration; noise=rng.uniform(-1,1); low=low*0.91+noise*0.09
        env=min(t*80,1)*(1-u)**2
        if name=='laser':
            phase+=2*math.pi*(1600*(1-u)**3+130)/RATE; value=(math.sin(phase)*0.65+noise*0.08)*env
        elif name=='impact': value=(low*2+math.sin(t*2*math.pi*85)*0.35)*env
        elif name=='explosion': value=(low*3.5+noise*0.12)*env
        elif name=='jump':
            phase+=2*math.pi*(60+u*u*750)/RATE; value=(math.sin(phase)*0.25)*(math.sin(math.pi*u)**0.6)
        elif name=='land': value=(math.sin(2*math.pi*t*330)+math.sin(2*math.pi*t*440))*0.2*env
        else: value=(math.sin(t*2*math.pi*55)*0.32+math.sin(t*2*math.pi*110)*0.1+low*0.35)*0.5
        samples.append(struct.pack('<h',int(max(-1,min(1,value))*18000)))
    # Keep advancing the seeded RNG to preserve other placeholder waveforms,
    # but never overwrite the recovered original explosion recording.
    if name=='explosion': continue
    with wave.open(str(ROOT/(name+'.wav')),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(b''.join(samples))
# Arrival is recovered original snd 130; never overwrite it with a placeholder.
print('Generated six placeholder sounds; preserved the original explosion recording.')
