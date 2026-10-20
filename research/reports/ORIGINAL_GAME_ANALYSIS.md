# Original Escape Velocity archive analysis

Analysis date: September 20, 2026.

## Result

The original game is directly inspectable. Downloaded and unpacked **Escape Velocity 1.0.5**, from the original Escape Velocity game line selected by the user. This is a later patch of that game, not a Nova conversion and not necessarily identical to the 1996 launch version.

The archive includes separate data, graphics, sound, music, and title resources, the executable, and the original documentation. Crucially, `EV Data` contains **17 embedded ResEdit templates** describing its binary fields. We can decode much of the game's content using the format descriptions shipped in the game itself.

This completes an initial resource analysis. It does not complete executable reverse engineering or produce a playable replacement.

## Acquisition and identity

- Source: [the user's Macintosh Repository page](https://www.macintoshrepository.org/6700-escape-velocity).
- Download: `Escape_Velocity_1.0.5.sit`, public download ID `9562`.
- Size: 5,191,661 bytes.
- SHA-1: `33f09cd3abe8747aaabdfb5ea8d1943d8b4363d8` — matches the page's published checksum.
- SHA-256: `52392bb8e3eff318fc085f0a50579b169c5bcaeca27a64f35ac6df434bab8ec2`.
- Archive format: StuffIt 5, identified by `lsar`.
- Extractor: official [Unarchiver command-line utility](https://theunarchiver.com/command-line), version 1.10.1, with resource forks preserved as AppleDouble files.

The checksum establishes that the downloaded file matches the archive listed on the page. It is not independent verification against a publisher-signed original distribution.

## Content recovered

Counts below come from parsing the downloaded binary resource maps, not from a wiki or an EV-for-Nova dataset.

| Content | Resource type | Count |
| --- | --- | ---: |
| Ship definitions | `shïp` | 27 |
| Weapon definitions | `wëap` | 26 |
| Outfits | `oütf` | 54 |
| Star systems | `sÿst` | 108 |
| Stellar objects, including planets and stations | `spöb` | 107 |
| Mission definitions | `mïsn` | 116 |
| Governments | `gövt` | 25 |
| Individual NPC definitions | `përs` | 220 |
| Encounter definitions | `düde` | 67 |
| Fleet definitions | `flët` | 19 |
| Special trade-good definitions | `jünk` | 19 |
| Economic event definitions | `öops` | 52 |
| Description resources | `dësc` | 644 |
| String lists in EV Data | `STR#` | 66 |
| Pictures in EV Graphics | `PICT` | 402 |
| Sprite layout definitions in EV Graphics | `spïn` | 81 |
| Sounds in EV Sounds | `snd ` | 59 |
| Sound resources in EV Music | `snd ` | 4 |

These are resource counts. They should not be interpreted as counts of purchasable ships, distinct ship models, landable worlds, independent storylines, or modern audio files. For example, the 27 ship records include an escape pod and two differently configured records named Kestrel.

## Concrete examples

Values below are decoded directly from `EV Data`, using its own `shïp` template. They retain original storage units. The labels do not establish modern-world units or per-second scaling.

| Resource ID | Name | Holds | Shield | Accel | Speed | Maneuver | Cost |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 128 | Shuttlecraft | 20 | 180 | 435 | 275 | 4 | 10,000 |
| 129 | Light Freighter | 150 | 150 | 190 | 125 | 2 | 280,000 |
| 143 | Kestrel | 80 | 1,300 | 375 | 225 | 3 | 10,000,000 |

Ship records also supply armor, recharge parameters, fuel, installed weapon IDs/counts, ammunition, equipment mass, crew, and requirements. Mission records supply availability conditions, cargo, payment, encounter parameters, text references, completion/failure bits, and flags. System records supply map coordinates, neighboring systems, stellar-object references, encounter choices, and government IDs.

The 108 systems contain 278 directed travel connections, representing 139 distinct undirected pairs. Every non-sentinel system connection and system navigation reference resolved to an existing record in this archive.

The original manual is recoverable as 11 `TEXT` resources in `Escape Velocity Documentation`. The extraction also found named commodity and base-price string lists.

## Executable findings and limits

The application data fork begins with `Joy!peffpwpc`, identifying a PowerPC PEF executable. Its resource fork also contains 12 `CODE` resources, consistent with the archive's classic Mac executable structure. At the time of this archive analysis, the original game had not been launched and no executable routines had been disassembled or translated. A subsequent session successfully launched Infinite Mac's bundled original-game copy and reached active flight; see [live reference notes](ORIGINAL_REFERENCE_PLAY.md). That copy's patch version and equivalence to this archive remain unverified.

Stored data does not by itself specify every runtime rule. Further analysis is needed for:

- Physics integration, timing, thrust and speed scaling, turning, and collision rules.
- Enemy targeting, steering, firing decisions, and special AI behavior.
- Exact interpretation of weapon timing, damage, recharge, flags, and special-case values.
- Mission-state transitions, special conditions, and generated mission behavior.
- Resource load/override order and version differences relevant to add-ons.
- Save-file semantics and consistency with the original engine.

Use documentation and targeted executable analysis to establish these rules, then compare behavior against the original running under an appropriate emulator. A faithful modern implementation can combine the recovered data model with newly implemented engine logic and upgraded presentation.

## Tools and validation

Created `tools/inspect_ev.py`, a Python standard-library resource reader. It unwraps AppleDouble files, parses resource maps, reads embedded templates, and exports structured JSON. It preserves resource IDs, names, attributes, source hashes, field offsets, and original numerical values. Unsupported template fields, truncated ranges, and duplicate resource IDs are rejected.

Validation performed:

- Parsed all 17 extracted resource-fork files: **2,820 total resources**.
- Exported **1,700 decoded records**, covering embedded-template types, string lists, and text resources throughout the distribution.
- All decoded records consumed their payloads exactly; no trailing bytes remained.
- Checked system connections and navigation references: no unresolved references.
- Passed seven focused parser tests covering bare forks, AppleDouble wrapping, signed values, rectangle fields, invalid ranges, unknown field types, and missing string terminators.

These checks validate structural decoding. They do not establish behavioral equivalence with the original engine.

## Local artifacts

- `research/downloads/Escape_Velocity_1.0.5.sit`: preserved archive.
- `research/extracted/Escape Velocity 1.0.5 ƒ/`: extracted application, documentation, and resources.
- `research/decoded/inventory.json`: individual resource metadata and hashes.
- `research/decoded/templates.json`: original field schemas and their source IDs.
- `research/decoded/decoded.json`: decoded resource values and documentation.
- `research/decoded/validation.json`: structural validation totals.
- `research/reports/archive-inventory.json`: compact source identity and per-file inventory.

Downloaded and generated resource files are excluded from Git; the extraction code and analysis reports remain available for version control.
