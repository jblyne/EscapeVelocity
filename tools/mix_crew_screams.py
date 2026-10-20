"""Layer saved ElevenLabs cries into brief, normalized crew reactions."""
from pathlib import Path
import array, math, wave
ROOT=Path(__file__).resolve().parents[1]/'godot/audio'
def read(name):
    with wave.open(str(ROOT/(name+'.wav')),'rb') as w:
        return array.array('h',w.readframes(w.getnframes()))
def generate():
    human=[read(f'death_cry_{i}') for i in range(1,7)]
    alien=[read(name) for name in ['death_cry_alien','death_cry_alien_2','death_cry_alien_3']]
    for family,sources in [('human',human),('alien',alien)]:
        for label,count in [('crew',3),('crowd',6)]:
            for variant in range(3):
                result=[0.0]*37485
                for layer in range(count):
                    source=sources[(layer+variant*2)%len(sources)]
                    speed=[.86,1.09,.98,1.18,.93,1.04][(layer+variant)%6]
                    delay=int([0,.027,.053,.012,.041,.068][(layer+variant)%6]*44100)
                    for i in range(delay,len(result)):
                        pos=(i-delay)*speed
                        at=int(pos)
                        if at+1>=len(source):break
                        value=source[at]+(source[at+1]-source[at])*(pos-at)
                        result[i]+=value
                peak=max(abs(v) for v in result)
                # Normalize the group, then fade its final edge to exactly silence.
                data=array.array('h',(int(v/peak*26000*min(1,(len(result)-1-i)/2205)) for i,v in enumerate(result)))
                name=f'death_cry_{family}_{label}'+('' if variant==0 else f'_{variant+1}')
                with wave.open(str(ROOT/(name+'.wav')),'wb') as out:
                    out.setnchannels(1);out.setsampwidth(2);out.setframerate(44100);out.writeframes(data.tobytes())
                print(name,count,'overlapping voices')
if __name__=='__main__':generate()
