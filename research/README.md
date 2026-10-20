# Original-game research

See [the analysis report](reports/ORIGINAL_GAME_ANALYSIS.md) for findings, evidence, and remaining reverse-engineering work.

The original game now runs in a Mac OS 7.6 browser emulator. See [live reference setup and observed differences](reports/ORIGINAL_REFERENCE_PLAY.md). The bundled emulator copy's patch version remains to be confirmed; keep it distinct from the verified 1.0.5 download below.

The source is the original-game **1.0.5** download on [Macintosh Repository](https://www.macintoshrepository.org/6700-escape-velocity). The current archive's SHA-1 must be `33f09cd3abe8747aaabdfb5ea8d1943d8b4363d8` to reproduce this scan.

Unpack with [the official Unarchiver command-line tool](https://theunarchiver.com/command-line), preserving resource forks:

```sh
unar -k visible -o research/extracted research/downloads/Escape_Velocity_1.0.5.sit
```

From the project root, decode the original resources:

```sh
python3 tools/inspect_ev.py 'research/extracted/Escape Velocity 1.0.5 ƒ' --output research/decoded
python3 -m unittest discover -s tools -p 'test_*.py' -v
```

The Python reader has no external dependencies. Its outputs preserve the original resource field names and storage units. It does not execute the game or translate machine code. Downloaded originals, extracted files, and generated resource JSON stay local and are excluded from Git.
