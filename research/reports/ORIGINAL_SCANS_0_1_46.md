# Original mission cargo scans — 0.1.46

20 October 2026. Scope: continue original-game fidelity without add-ons.

## Confirmed source rules

Reference is the bundled original Escape Velocity 1.0.5 PowerPC executable, decoded read-only with `tools/unpack_ev_executable.py` and `tools/disassemble_ev_reference.py`.

- Scan routine 0x210 checks AI types 3 and 4 at 0x244–0x258.
- It rejects a missing government and a zero smuggling penalty at 0x25c–0x284. The government loader at 0x255d0–0x25614 copies the five source penalty words from resource offset 0x0a into the runtime table beginning at 0x28, so the first word tested by the scan routine is `SmugPenalty`.
- Government matching at 0x290–0x2ac compares the scanner's government with the mission's exact ScanGovt, not an ally/enemy approximation. Mission-resource loading converts the resource ID to an index at 0x53e00–0x53e34; both sides use that same government table.
- 0x2bc–0x2f0 requires picked-up cargo and a nonnegative cargo type.
- 0x2f4–0x340 compares absolute X and Y offsets independently with the double at TOC -0x6b18, which is 180. The boundary is inclusive. This is a square range, not the remake's old 450-unit circle.

## Changes

The mission scanner now applies these eligibility rules. Player-owned/protected escorts and ships already departing are excluded from patrol scanning; these remake ownership/departure markers correspond to different original AI states. Cloaking and delivered/uncollected cargo remain protected from detection. Scans cannot run in paused menus.

The original catalog field is `SmugPenalty`. The old call used nonexistent `SmugglePenalty`, which would raise a script error when a real detection reached the legal-penalty path. The corrected detection applies the actual penalty, routes FailIfScan missions through ordinary failure handling, and saves the resulting legal/mission state. The existing once-per-patrol/per-mission detection marker prevents repeated penalties from the same contact. Each patrol processes at most one illegal cargo per scan opportunity, matching the original routine's return after its first matching mission at 0x488; multiple illegal contracts do not multiply one scan into several immediate penalties.

The five-second scan scheduler now retains fractional elapsed time across frame boundaries and resets when a new system or post-landing traffic encounter starts. Duplicate encounter-spawn polling on scan ticks was removed; ordinary mission updates already perform that work.

## Validation

`godot/tests/test_cargo_scans.gd` covers the 180-unit per-axis boundary, wrong and related governments, both valid patrol AI types and invalid types, disabled/owned/protected/departing contacts, governments with zero smuggling enforcement, cloaking, paused play, missing/delivered cargo, actual penalty values, duplicate suppression, FailIfScan mission failure, disk reload, fractional scheduler time, multiple illegal contracts, and encounter resets. Mission/campaign, arrival, encounter, launch-traffic, and boarding regressions accompany the change.

## Remaining comparison limits

The five-second scan interval is still remake cadence. The original invokes the scan check from its AI approach state (call at 0x339c), with additional relative-motion checks before that state completes. This update does not claim to reproduce that acquisition/approach timing or infer a wall-clock speed threshold from unmeasured original velocity units.

Further investigation also located a mission auxiliary-arrival counter initialized to 70 plus random(70), decremented in the original encounter updater. It must not be confused with a verified three-second main-group arrival delay: the runtime counter gates auxiliary fields. Its real-time cadence and the main-group entry sequence still need separate controlled comparison before replacing working campaign encounter timing.

Full manual original campaign playthroughs and exact flight/AI cadence remain open. No add-on support is included.

Release regression results: cargo scans 29 checks, missions 284, nine campaign routes 457, mission arrivals 11, original encounters 174, launch traffic 12, and communications/boarding 73; all zero failures. The launch-traffic fixture now checks ambient density separately from persistent escorts and named contacts and checks fleet identity instead of comparing expanded save records with an obsolete one-field dictionary.

The macOS bundle reports version 0.1.46, exported successfully, and completed an isolated fresh-pilot boot. The same 29 scan checks also pass against its packaged resources.
