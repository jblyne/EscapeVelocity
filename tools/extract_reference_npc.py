"""Read-only EV 1.0.5 instruction/constant evidence for the Phase 3 pass."""
import hashlib,json,struct
from pathlib import Path
from unpack_ev_executable import sections

def extract():
    code,data,_=sections()
    def instruction(address,expected):
        assert code[address:address+4].hex()==expected,hex(address)
    def double(toc):return struct.unpack_from('>d',data,0x8000+toc)[0]
    for address,expected in [(0x62644,'a8e3005a'),(0x62648,'2c070000'),
                             (0x62650,'c9029c40'),(0x62654,'ffff0232'),
                             (0x339c,'4bffce75'),(0x1dc64,'7f280735')]:
        instruction(address,expected)
    return {'reference':'Escape Velocity 1.0.5 PowerPC executable',
            'code_sha256':hashlib.sha256(code).hexdigest(),
            'npc_follow_slot_nonzero_speed_multiplier':double(-0x63c0),
            'npc_special_byte_6e_speed_multiplier_unmapped':double(-0x6398),
            'inspection_axis_distance_reference_coordinates':double(-0x6b18),
            'inspection_axis_relative_motion_reference_coordinates_per_tick':double(-0x6b50),
            'player_bomb_velocity_multiplier':double(-0x6908),
            'player_projectile_drift_excluded_guidance':[4,7,8],
            'npc_projectiles_inherit_velocity':False,
            'addresses':{'npc_speed':'0x62548-0x62680','inspection_motion':'0x317c-0x339c',
                         'player_projectile_inheritance':'0x1dc64-0x1dd6c'},
            'limits':'Constants and branches, not a complete original AI state-machine port. Runtime byte 0x6e meaning is not established.'}
if __name__=='__main__':
    result=extract()
    path=Path(__file__).resolve().parents[1]/'research/decoded/reference-npc.json'
    path.write_text(json.dumps(result,indent=2)+'\n');print(path)
