"""Read-only EV 1.0.5 bribery/title-secret instruction evidence for Phase 5."""
import hashlib,json,struct
from pathlib import Path
from unpack_ev_executable import sections

def extract():
    code,data,_=sections()
    checks={0xefa0:'554a05ad',0xefc8:'38600029',0xf0a4:'1c6303e8',
            0x10a44:'38630bb8',0x10d90:'2c07001e',0x12c94:'1f7b0064',
            0x4bb2c:'38600032',0x4bb7c:'3860000b',0x4bba4:'3860003f',
            0x4bbc4:'3860003f',0x453b0:'38800b54',0x453bc:'38601450'}
    # Pin the specific executable and the branches used by the implementation.
    for address,expected in checks.items():
        actual=code[address:address+4].hex()
        assert actual==expected,(hex(address),actual,expected)
    constants={name:struct.unpack_from('>d',data,0x8000+offset)[0] for name,offset in {
        'mood_percent':-0x6a20,'mood_swing':-0x6a28,'ship_wallet_random_bound':-0x6a30,
        'expensive_ship_wallet_bound':-0x6a38,'wallet_price_cap_fraction':-0x6a40,
        'landing_wallet_random_bound':-0x6a60,'expensive_landing_multiplier':-0x6a68,
        'receiving_negotiation_multiplier':-0x6a70,'paying_negotiation_multiplier':-0x6a78}.items()}
    return {'reference':'Escape Velocity 1.0.5 PowerPC executable',
            'code_sha256':hashlib.sha256(code).hexdigest(),'constants':constants,
            'price_bounds':[1000,900000],'quote_rounding':1000,'negotiation_rounding':100,
            'landing_willingness':'random(100) > 30 and (government == -1 or government.Flags & 0x4000)',
            'price_government_flag':32768,'negotiation_success':'random(100) <= 50',
            'key_map':'GetKeys reads big-endian 16-bit words: tested bit index = Mac virtual key code XOR 8',
            'about_keys':{'option_bit':50,'F_bit':11,'control_bit':51,'command_bit':63},
            'satellite':{'description':2900,'picture':5200,'verified_playable_stats':False},
            'addresses':{'ship_quote':'0xefc8-0xf2a8','landing_quote':'0x109ec-0x10bbc',
                         'landing_willingness':'0x10d64-0x10e5c','negotiation':'0x12ad4-0x12ca8',
                         'about_modifiers':'0x4bb2c-0x4bc54','key_reader':'0x606e0-0x60750',
                         'satellite_display':'0x4539c-0x453cc'},
            'limits':'Modern random generator; stable per-contact/per-port-day quotes. Legacy signed-16-bit wallet-bound overflow is not emulated. Satellite preview only; no invented secret hull.'}
if __name__=='__main__':
    result=extract();path=Path(__file__).resolve().parents[1]/'research/decoded/reference-bribes.json'
    path.write_text(json.dumps(result,indent=2)+'\n');print(path)
