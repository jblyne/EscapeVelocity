# Phase 3 — NPC behavior and encounters (0.1.164)

21 October 2026. Base-game scope; requested Maverick, tribute hunters, assistance, firing controls and other custom features retained.

## Reference

The local Escape Velocity 1.0.5 PowerPC code/data sections are the primary reference. `python3 tools/extract_reference_npc.py` checks instructions and extracts constants into `research/decoded/reference-npc.json`, including its executable checksum. These are read-only binary comparisons, not emulator timing measurements.

- Speed helper 0x62548–0x62680 loads source hull speed. Non-player ships whose follow slot (0x5a) is nonzero use 1.25×; slot zero follows the player and uses base speed. The remake now applies these rules to ordinary NPCs and player escorts, including departure setup, replacing the arbitrary idle 0.65× cap. Maverick's custom flight fields retain their existing handling.
- Inspection approach at 0x317c–0x339c tests both position axes against 180 original coordinates, then both relative-velocity axes strictly below 0.35 coordinates/tick before calling the scan routine. Under Phase 2's 5/3 distance scale and nominal 60 Hz, these become an inclusive 300-unit square and strict 35-unit/second per-axis motion limits. The previous unscaled 180-unit range was corrected. Government, mission cargo, cloak and ownership restrictions remain.
- Launch routine 0x1dc64–0x1dd6c copies player velocity into ordinary projectile initial motion, excluding guidance types 4/7/8 (turrets/swivel). NPC launches skip that copy. Guidance 5 halves the combined initial velocity. Original weapons now apply those launch rules. Custom M61/Sidewinders retain their requested motion; reflected weapons clear inherited drift.

## Behavior changes

Civilian ships now recognize nearby pirate threats and actual attackers, including same-government aggressors. A previously unconditional civilian exclusion prevented their evasion/retaliation. Wimpy merchants flee without firing; armed merchants can defend themselves, and their collision permissions now agree with that choice. Disabled/departing ships are excluded from new NPC target acquisition.

Ambient merchants and pirates break off combat when severely damaged. Their escape uses the existing hyperspace departure engine after withdrawal, rather than deleting the contact. Story actors, named captains, carrier fighters, player fleet and tribute hunters retain their separate lifecycle rules. Tribute hunters cannot silently escape through ordinary ambient-departure logic.

Eligible, nonhostile patrols acquire a nearby illegal-cargo carrier, approach, brake and match its motion. A completed approach invokes the mission scanner for that individual patrol immediately. Fast fly-bys cannot complete a scan. A completed scan is remembered per patrol/mission; cloaking stops acquisition. The existing five-second poll remains a fallback opportunity for otherwise eligible contacts and retains fractional scheduler time.

Weighted encounter-table selection, government links, density and contact caps remain. New ambient arrivals enter with an inward heading and velocity instead of appearing stationary. Initial population stops cleanly if the contact cap is full. Existing port landings, NPC jumps, mission escape events, launch refresh, pause and system-transition cleanup are regression-tested.

## Tuning and limits

The 1,400-unit patrol acquisition radius, 100-unit approach stand-off, 25% shield retreat threshold (80% hull for unshielded ships), eight-second withdrawal and ambient arrival intervals are explicit remake tuning, not recovered original AI constants. Named-person aggression/retreat/radio behavior retains its previously documented tuning. The recovered speed helper also contains a 0.333× branch on runtime byte 0x6e; its meaning is not established, so that branch is recorded without assigning an invented gameplay meaning.

General combat pursuit still uses the existing bounded intercept estimate and smooth vector flight. Missile guidance retains the existing steering algorithm with inherited drift, rather than claiming a complete port of the original guidance state machine. This pass delivers the NPC behavior baseline; exact original branch timing and manual long-session comparison remain acceptance work. Fleet endurance, recall, docking and carrier lifecycle remain Phase 4.

## Validation

Focused NPC tests cover every original hull's speed, civilian evasion and defending-shot collisions, wounded pirate withdrawal, mission/tribute exclusions, actual patrol approach, relative-motion boundaries, cloak and duplicate inspection protection, original player/NPC projectile drift exceptions, custom Sidewinders, inward arrivals and pause. Regression suites cover cargo scans, timing, departures, ambient launch refresh, named captains, original encounters, all nine campaign routes, missions/arrivals, fleets, firing controls, combat fidelity, Maverick, tribute hunters and repair assistance. See the final run counts in the task response. Native source checks, exported Mac signature and startup are checked separately; full manual campaigns remain Phase 6.

Final source run: 2,676 checks across 18 suites, all passing. The focused NPC suite also passed 64 checks with the native renderer. The universal Mac app was exported as 0.1.164 and verified with strict code-signature and startup checks. No GitHub push or release was made.
