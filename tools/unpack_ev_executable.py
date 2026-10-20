"""Decode the original PEF data section for read-only reference analysis.
Apple PEF pattern-initialization format, Mac OS Runtime Architectures ch. 8.
"""
from pathlib import Path
import struct
ROOT=Path(__file__).resolve().parents[1]
def unpack(data):
    at=0;out=bytearray()
    def count():
        nonlocal at
        result=0
        while True:
            b=data[at];at+=1;result=(result<<7)|(b&127)
            if not b&128:return result
    def block(n):
        nonlocal at
        result=data[at:at+n];at+=n;return result
    while at<len(data):
        b=data[at];at+=1;op=b>>5;n=b&31
        if n==0:n=count()
        if op==0:out.extend(bytes(n))
        elif op==1:out.extend(block(n))
        elif op==2:
            repeat=count();pattern=block(n);out.extend(pattern*(repeat+1))
        elif op in [3,4]:
            custom=count();repeat=count();pattern=block(n) if op==3 else bytes(n)
            for i in range(repeat):out.extend(pattern);out.extend(block(custom))
            out.extend(pattern)
        else:raise ValueError(op)
    return bytes(out)
def sections():
    source=next((ROOT/'research/extracted').rglob('Escape Velocity'))
    data=source.read_bytes();count=struct.unpack_from('>H',data,32)[0]
    result=[]
    for i in range(count):
        name,address,total,unpacked,packed,offset,kind,share,align,reserved=struct.unpack_from('>i5IBBBB',data,40+i*28)
        raw=data[offset:offset+packed]
        decoded=unpack(raw) if kind==2 else raw
        if kind in [0,1,2]: assert len(decoded)==unpacked
        result.append(decoded)
    return result
if __name__=='__main__':
    for i,s in enumerate(sections()):
        path=Path('/tmp')/f'ev-section-{i}.bin';path.write_bytes(s);print(path,len(s))
