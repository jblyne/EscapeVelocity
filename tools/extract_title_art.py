"""Decode indexed PackBitsRect PICTs from the local original title resource fork."""
from pathlib import Path
import struct
from PIL import Image
from inspect_ev import read_resources

def decode(data):
    pos=data.index(b'\x00\x98',40)+2
    rowbytes=struct.unpack_from('>H',data,pos)[0]&0x3fff
    top,left,bottom,right=struct.unpack_from('>hhhh',data,pos+2)
    depth=struct.unpack_from('>H',data,pos+28)[0]
    assert depth in (4,8), 'Expected indexed pixels'
    pos+=46
    flags=struct.unpack_from('>H',data,pos+4)[0]
    count=struct.unpack_from('>H',data,pos+6)[0]+1
    pos+=8
    palette=[0]*768
    for entry in range(count):
        index,r,g,b=struct.unpack_from('>HHHH',data,pos);pos+=8
        if flags & 0x8000: index=entry
        palette[index*3:index*3+3]=[r>>8,g>>8,b>>8]
    pos+=18 # source and destination rectangles, transfer mode
    pixels=bytearray()
    for y in range(bottom-top):
        length=struct.unpack_from('>H' if rowbytes>250 else '>B',data,pos)[0]
        pos+=2 if rowbytes>250 else 1
        packed=data[pos:pos+length];pos+=length
        row=bytearray();i=0
        while i<len(packed):
            n=packed[i];i+=1
            if n<128: row.extend(packed[i:i+n+1]);i+=n+1
            elif n>128: row.extend([packed[i]]*(257-n));i+=1
        assert len(row)==rowbytes
        if depth==4: row=bytearray(v for byte in row for v in (byte>>4,byte&15))
        pixels.extend(row[:right-left])
    image=Image.frombytes('P',(right-left,bottom-top),bytes(pixels));image.putpalette(palette)
    return image.convert('RGB')

if __name__=='__main__':
    source=next(Path('research/extracted').rglob('EV Titles.rsrc'))
    out=Path('godot/assets/classic');out.mkdir(parents=True,exist_ok=True)
    for item in read_resources(source.read_bytes()):
        if item['type']=='PICT' and (item['id'] in [8000,8001,8002,128] or 8300<=item['id']<=8316):
            decode(item['data']).save(out/f"{item['id']}.png")
