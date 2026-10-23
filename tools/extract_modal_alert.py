"""Render the original System 7 Simple Beep command resource into cached PCM.

The original game invokes Macintosh SysBeep rather than one of EV Sounds' Beep
samples. Data is recovered from System 7.5.3 snd 1 and snth 4097. Reproduce its
256-byte timbre wavetable using the original integer lookup and mirroring
routine at snth offsets 0x2d8..0x38e. The quarter-sine table is at 0x3b6.
The note-69 phase step is from that same synthesizer. waitCmd uses 1/2000 s.
The source disk is not bundled; tiny recovered commands/tables are in JSON.
"""
from pathlib import Path
import json
import wave
ROOT=Path(__file__).resolve().parents[1]

def wavetable(lookup,amplitude,timbre):
    result=[128]*256
    split=(256-timbre)//2
    for start,end,sign in [(0,split,1),(split,256,-1)]:
        phase=0
        step=0x1000000//max(1,end-start)
        left,right=start,end
        while left<right:
            sample=128+sign*((lookup[phase>>16]*amplitude)>>8)
            result[left]=sample
            right-=1
            result[right]=sample
            left+=1
            phase+=step
    return result

def render(data):
    amplitude=0;timbre=0;note=69;phase=0;elapsed=0
    pcm=bytearray()
    for command,param1,param2 in data['commands']:
        if command==44:timbre=param1
        elif command==43:amplitude=param1
        elif command==42:note=param2
        elif command==10:
            assert note==69,'Only the recovered alert note is needed'
            table=wavetable(data['quarter_sine_table'],amplitude,timbre)
            elapsed+=param1
            end=round(elapsed*data['sample_rate']/2000)
            while len(pcm)<end:
                pcm.append(table[(phase>>16)&255])
                phase+=data['note_69_phase_step']
        else:raise ValueError(f'Unexpected sound command {command}')
    return bytes(pcm)

if __name__=='__main__':
    data=json.loads((ROOT/'godot/data/classic_modal_alert.json').read_text())
    pcm=render(data)
    path=ROOT/'godot/audio/modal_alert.wav'
    with wave.open(str(path),'wb') as out:
        out.setnchannels(1);out.setsampwidth(1);out.setframerate(data['sample_rate']);out.writeframes(pcm)
    print(f'{path.name}: {len(pcm)} samples, {len(pcm)/data["sample_rate"]:.3f} seconds')
