"""Original synthesized Maverick effects; contains no film soundtrack samples."""
import math, random, struct, wave
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'godot/audio'
def save(name,samples):
 with wave.open(str(root/(name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(22050)
  f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,s))*24000)) for s in samples))
rng=random.Random(14)
save('maverick_gun',[(rng.uniform(-1,1)*.65+math.sin(i/22050*math.tau*95)*.35)*math.exp(-i/22050*65) for i in range(2205)])
# A short original ascending synth fanfare, not an arrangement of Top Gun music.
notes=[(0,.18,220),(.18,.18,293.66),(.36,.24,369.99),(.60,.50,440),(.60,.50,554.37),(.60,.50,659.25)]
samples=[]
for i in range(28665):
 t=i/22050;value=0
 for start,duration,freq in notes:
  age=t-start
  if 0<=age<duration:
   env=min(1,age/.015)*min(1,(duration-age)/.14)
   value+=(math.sin(math.tau*freq*age)+.2*math.sin(math.tau*freq*2*age))*.17*env
 samples.append(value)
save('maverick_victory',samples)
