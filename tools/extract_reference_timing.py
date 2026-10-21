"""Extract timing evidence from the local EV 1.0.5 executable, read-only.

No emulation or wall-clock measurements are claimed by this extractor. The
original loop waits for the next Macintosh TickCount tick; 60 Hz is its upper
update rate on a sufficiently fast machine. Vintage slowdowns remain distinct
from the remake's deterministic simulation clock.
"""
import hashlib
import json
import struct
from pathlib import Path
from unpack_ev_executable import sections

ROOT = Path(__file__).resolve().parents[1]


def extract():
    code, data, loader = sections()
    def double(toc):
        return struct.unpack_from('>d', data, 0x8000 + toc)[0]
    def instruction(address, expected):
        actual = code[address:address + 4].hex()
        assert actual == expected, (hex(address), actual, expected)
    # Import run at the start of data relocation binds the first 307 words to
    # imports in order. Stub 0x7762c loads TOC -0x7e24, word 119: TickCount.
    header = struct.unpack_from('>14I', loader)
    imports = 56 + header[6] * 24
    assert struct.unpack_from('>H', loader, header[9])[0] == 0x4b32
    symbol = struct.unpack_from('>I', loader, imports + 119 * 4)[0] & 0xffffff
    assert loader[header[10]+symbol:].split(b'\0',1)[0] == b'TickCount'
    instruction(0x7762c, '818281dc')
    instruction(0x15964, '48061cc9')  # bl TickCount stub, start of update
    instruction(0x15b30, '48061afd')  # bl TickCount stub, wait loop
    instruction(0x15b38, '3863ffff')  # current tick - 1
    instruction(0x24744, 'fc211824')  # Accel / divisor
    instruction(0x24788, 'fc843024')  # Speed / divisor
    instruction(0x623d4, 'fca507f2')  # Maneuver * game-speed factor
    instruction(0x3659c, 'fc42e82a')  # signed integrity + 1% shields
    instruction(0x365a0, 'fc40101e')  # truncate result toward zero
    values = {
        'acceleration_divisor': double(-0x68b0),
        'speed_divisor': double(-0x68b8),
        'normal_acceleration_multiplier': double(-0x63a8),
        'player_speed_multiplier': double(-0x63b8),
        'shield_fraction_per_pulse': double(-0x6748),
        'npc_shield_fraction_per_pulse': double(-0x6940),
    }
    assert values == {'acceleration_divisor':10000.,'speed_divisor':100.,
                      'normal_acceleration_multiplier':2.,'player_speed_multiplier':1.75,
                      'shield_fraction_per_pulse':.01,'npc_shield_fraction_per_pulse':.01}
    return {
        'reference':'Escape Velocity 1.0.5 PowerPC code/data sections',
        'code_sha256':hashlib.sha256(code).hexdigest(),
        'basis':'Executable instructions and decoded constants; not emulator wall-clock measurements',
        'normal_tick_hz':60,'update_counter_wrap':1025,
        'world_units_per_reference_coordinate':5/3,
        'world_scale_basis':'Remake coordinate choice preserving raw weapon Speed as world units/second',
        'constants':values,
        'addresses':{'main_loop':'0x15874-0x15bc0','ship_loader':'0x24718-0x247bc',
                     'acceleration_helper':'0x62400-0x62544','speed_helper':'0x62548-0x62680',
                     'turn_helper':'0x622b0-0x623fc','player_recovery':'0x364e0-0x365e8',
                     'npc_recovery':'0x18740-0x18804','projectile_lifetime':'0x1ddc0-0x1de18'},
    }

if __name__ == '__main__':
    result=extract()
    path=ROOT/'research/decoded/reference-timing.json'
    path.write_text(json.dumps(result,indent=2)+'\n')
    print(path)
