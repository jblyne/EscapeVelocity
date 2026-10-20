"""Extract original explosion, forklift engine, and cloak samples without synthesis.

Standard uncompressed Sound Manager headers contain unsigned 8-bit mono PCM.
The integer WAV rate rounds the original 16.16 rate by less than 0.3 Hz.
"""
from pathlib import Path
import struct
import wave
from inspect_ev import read_resources
from extract_title_art import decode
ROOT=Path(__file__).resolve().parents[1]

def pcm_sound(data):
    fmt=struct.unpack_from('>H',data)[0]
    if fmt==1:
        count=struct.unpack_from('>H',data,2)[0]
        pos=4+count*6
    elif fmt==2: pos=4
    else: raise ValueError('Unsupported sound resource format')
    commands=struct.unpack_from('>H',data,pos)[0];pos+=2
    for i in range(commands):
        command,param,offset=struct.unpack_from('>HHI',data,pos+8*i)
        if command&0x7fff!=81: continue
        pointer,length,rate,start,end,encoding,base=struct.unpack_from('>IIIIIBB',data,offset)
        assert encoding==0, 'Only uncompressed standard sound headers are supported'
        pcm=data[offset+22:offset+22+length]
        assert len(pcm)==length
        return pcm,round(rate/65536)
    raise ValueError('No sound-buffer command')

if __name__=='__main__':
    source=next((ROOT/'research/extracted').rglob('EV Sounds.rsrc'))
    names={223:'forklift',341:'cloak_on',340:'cloak_off',303:'explosion',300:'heavy_explosion'}
    for r in read_resources(source.read_bytes()):
        if r['type']=='snd ' and r['id'] in names:
            pcm,rate=pcm_sound(r['data'])
            with wave.open(str(ROOT/'godot/audio'/f'{names[r["id"]]}.wav'),'wb') as out:
                out.setnchannels(1);out.setsampwidth(1);out.setframerate(rate);out.writeframes(pcm)
            print(names[r['id']],len(pcm),rate)
    source=next((ROOT/'research/extracted').rglob('EV Graphics.rsrc'))
    for r in read_resources(source.read_bytes()):
        if r['type']=='PICT' and r['id']==230:
            out=ROOT/'research/decoded/forklift-reference.png'
            decode(r['data']).crop((0,0,96,96)).save(out)
