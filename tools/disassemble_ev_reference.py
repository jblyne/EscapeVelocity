"""Read-only EV 1.0.5 PowerPC reference; requires the optional capstone package.

Run: python3 tools/disassemble_ev_reference.py
Output is temporary disassembly, not a replacement engine or shipped asset.
"""
from pathlib import Path
from unpack_ev_executable import sections


def main():
    try:
        from capstone import Cs, CS_ARCH_PPC, CS_MODE_32, CS_MODE_BIG_ENDIAN
    except ImportError as exc:
        raise SystemExit('Install capstone in a temporary Python environment to use this analysis tool.') from exc
    engine = Cs(CS_ARCH_PPC, CS_MODE_32 | CS_MODE_BIG_ENDIAN)
    engine.skipdata = True
    output = Path('/tmp/ev-ppc.txt')
    output.write_text('\n'.join(f'{i.address:08x}: {i.mnemonic} {i.op_str}'
                                for i in engine.disasm(sections()[0], 0)) + '\n')
    print(output)


if __name__ == '__main__':
    main()
