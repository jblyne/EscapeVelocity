"""Deterministic synthesized battle-station effects; no film recordings used."""
from pathlib import Path
import math
import random
import struct
import wave
ROOT=Path(__file__).resolve().parents[1]
RATE=22050

def render(name,duration):
    rng=random.Random(572)
    data=[];low=0.0;phase=0.0
    for i in range(int(duration*RATE)):
        t=i/RATE;p=t/duration
        white=rng.uniform(-1,1);low=low*.985+white*.015
        if name=='death_star_warp':
            envelope=math.sin(math.pi*p)**.6
            value=(low*4+white*.12+math.sin(2*math.pi*(65*t+90*t*t))*.18)*envelope
        elif name=='death_star_charge':
            # A restrained reactor rumble and filtered energy wash. Avoid the
            # old wobbling oscillator and eight sharp, arcade-like chirps.
            phase+=2*math.pi*(46+12*p*p)/RATE
            envelope=min(1,t/.65)*min(1,(duration-t)/.18)
            body=math.sin(phase)*.16+math.sin(phase*1.503)*.055
            wash=low*(1.8+1.8*p)
            value=(body+wash)*(.28+.55*p)*envelope
            for emitter in range(8):
                onset=t-emitter*.22
                if 0<onset<.65:
                    # Soft breath of energy follows each extending beam.
                    swell=math.sin(math.pi*onset/.65)**2
                    value+=low*.65*swell*min(1,onset/.08)
        else:
            envelope=min(1,t/.035)*min(1,(duration-t)/.25)
            value=(low*5+white*.13+math.sin(2*math.pi*52*t)*.22+math.sin(2*math.pi*208*t)*.08)*envelope
        data.append(math.tanh(value*1.6))
    peak=max(abs(v) for v in data)
    pcm=b''.join(struct.pack('<h',int(v/peak*.8*32767)) for v in data)
    path=ROOT/'godot/audio'/f'{name}.wav'
    with wave.open(str(path),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(RATE);out.writeframes(pcm)
    print(path.name,len(data)/RATE)

if __name__=='__main__':
    for name,duration in [('death_star_warp',3),('death_star_charge',11),('death_star_fire',4)]:
        render(name,duration)
