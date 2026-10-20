"""Mix one final-words line with a continuous crew bed for each wreck section."""
from pathlib import Path
import array, wave
ROOT=Path(__file__).resolve().parents[1]/'godot/audio'
RATE=44100

def read(name):
    with wave.open(str(ROOT/(name+'.wav')),'rb') as w:
        assert w.getframerate()==RATE and w.getnchannels()==1
        return array.array('h',w.readframes(w.getnframes()))

def mix(name, foreground, cries, variant):
    result=[0.0]*(RATE*6)
    def add(source, at, gain):
        start=round(at*RATE)
        for i,v in enumerate(source):
            if start+i>=len(result): break
            result[start+i]+=v*gain
    for at,clip in foreground: add(read(clip),at,1.0)
    for i in range(12):
        add(read(cries[(i+variant)%len(cries)]),i*.5,.38 if foreground else .8)
        add(read(cries[(i+variant+2)%len(cries)]),i*.5+.23,.20 if foreground else .4)
    gain=24000/max(abs(v) for v in result)
    pcm=array.array('h',(int(v*gain*min(1,i/441,(len(result)-1-i)/441)) for i,v in enumerate(result)))
    with wave.open(str(ROOT/(name+'.wav')),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(RATE);out.writeframes(pcm.tobytes())
    print(name,'6-second normalized crew loop')

def generate():
    cries=[f'death_cry_{i}' for i in range(1,7)]
    for take in [1,2]:
        for variant,kind in enumerate(['end','no','fathers','regret','engines','family']):
            mix(f'wreck_{kind}_{take}',[(0,f'wreck_line_{kind}_{take}')],cries,take+variant*3)
        mix(f'wreck_alien_{take}',[],['death_cry_alien','death_cry_alien_2','death_cry_alien_3'],take)
if __name__=='__main__':generate()
