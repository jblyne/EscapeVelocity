# Ships, traffic, and factions — v0.1.14

## Recovered source

Original Escape Velocity 1.0.5 `EV Data.rsrc` contains 27 `shïp` records, 67 `düde` encounter groups, 25 `gövt` records, and 108 `sÿst` systems. `EV Graphics.rsrc` supplies corresponding `spïn` ship sprite definitions. All original fields are preserved unchanged in the generated catalog. The new `ship_graphics` section adds original sprite IDs and dimensions; it does not rewrite source values.

System `DudeTypes` and `% Prob` choose encounter groups. Each encounter supplies its own `ShipTypes`, weights, government, and AI type. The remake normalizes positive weights at each level, including systems whose listed weights sum to more than 100. It uses `AvgShips` for ambient population. Initial samples avoid duplicate hulls where possible; later arrivals sample the full weighted distribution. This sampling policy is a remake interpretation, not a recovered engine algorithm.

Sol's groups are Confederate merchants, warships, interceptors, and luxury traffic. Rebel regions, pirate activity, Astex freighters, Cydonian and Lethean forces, and militia follow their actual source tables. Government is assigned from the encounter, so the same civilian hull can have different affiliations.

21 ship records occur in ambient system tables. Hawk, Alien Fighter, Alien Cruiser, alternate Kestrel, Escort Carrier, and Escape Pod are special records. They are implemented and selectable in the debug menu, but are not injected into routine traffic. Carrier bays launch their source fighter type. Original mission triggers for special encounters are not yet implemented.

## Ship models

All 27 sprite sheets were decoded locally as visual references; reference thumbnails are in `research/decoded/ship-reference/`. Modern models are newly authored procedural geometry, with recognizable source silhouettes and frame-size proportions. The two Kestrel records intentionally share a silhouette, just as the original does; the original Escort Carrier shares the Bulk Freighter sprite, with added modern hangar detail here. Shared packed models reuse geometry and materials. Target previews copy the actual selected model.

| ID | Ship | Source sprite size | Inherent government |
| --- | --- | --- | --- |
| 128 | Shuttlecraft | 24 × 24 | Independent |
| 129 | Light Freighter | 48 × 48 | Independent |
| 130 | Bulk Freighter | 72 × 72 | Independent |
| 131 | Courier | 32 × 32 | Independent |
| 132 | Argosy | 48 × 48 | Independent |
| 133 | Confederate Frigate | 48 × 48 | Confederation |
| 134 | Confederate Cruiser | 72 × 72 | Confederation |
| 135 | Confed Patrol Ship | 32 × 32 | Confederation |
| 136 | Rapier | 32 × 32 | Independent |
| 137 | Lightning | 32 × 32 | Independent |
| 138 | Defender | 32 × 32 | Independent |
| 139 | Executive Transport | 32 × 32 | Independent |
| 140 | Luxury Liner | 48 × 48 | Independent |
| 141 | Rebel Destroyer | 48 × 48 | Rebellion |
| 142 | Rebel Cruiser | 64 × 64 | Rebellion |
| 143 | Kestrel | 48 × 48 | Independent |
| 144 | Manta | 32 × 32 | Rebellion |
| 145 | Scoutship | 32 × 32 | Independent |
| 146 | Corvette | 48 × 48 | Independent |
| 147 | Confed Gunboat | 32 × 32 | Confederation |
| 148 | Hawk | 32 × 32 | Independent |
| 149 | Alien Fighter | 32 × 32 | Aliens |
| 150 | Alien Cruiser | 48 × 48 | Aliens |
| 151 | Clipper | 32 × 32 | Independent |
| 152 | Kestrel | 48 × 48 | Independent |
| 153 | Escort Carrier | 72 × 72 | Rebellion |
| 191 | Escape Pod | 16 × 16 | Independent |

## Behavior and limits

- Flight uses each hull's Speed, Accel, and Maneuver, with the existing remake conversions. Peaceful traffic cruises at 65% of its speed; combat/evasion uses full speed. AI types 1–2 are treated as civilian traffic, 3–4 as military patrols. Type 1 evades attackers. These role interpretations and steering are provisional.
- NPC durability is the combined source shield and armor pool, displayed as integrity. The Alien Cruiser's negative signed shield word is provisionally interpreted as unsigned (62536); this is explicitly unverified engine behavior. NPC shield regeneration and separate armor damage are not implemented.
- Installed WeapType/WeapCount/AmmoLoad select armament. Missile and bay ammunition is finite. Reload uses the existing 60 Hz conversion, scaled by installed count and bounded to 0.12 seconds to keep combat practical. Guidance, range, damage conversion, targeting, and rate limits remain remake rules. NPC beams and missiles correctly distinguish their owner, other NPCs, and the pilot.
- Enemy/Ally IDs drive fleet relationships. Aliens and pirates are hostile; named hostile mission-government variants receive explicit provisional behavior. Undocumented government flag bits are not asserted to have verified meanings. Pirates may raid civilian ships; Confederate/Rebel and regional/corporate rivals can fight without involving the pilot. NPC projectiles do not inflict friendly fire on allied hulls.
- First player damage to a contact applies its government's ShootPenalty once; destruction applies KillPenalty once. Nearby allied military contacts retaliate. Scores persist in the optional `reputation` save field. A faction becomes hostile below `-max(10, CrimeTol)`; that threshold policy is provisional. Old saves default to initial standing, and corrupt faction records fail atomically. This does not implement campaign allegiance, promotions, bribes, faction mission eligibility, or landing refusals.
- Ambient replacements arrive every 8–14 seconds when below source population. Civilian arrivals at their goal can dock/despawn; old or distant unengaged contacts retire. Pause freezes all of this. Limits: 32 NPC contacts, four active fighters per NPC carrier, 160 NPC projectiles, eight simultaneous explosions. Player debug escorts retain their separate 12-ship limit.
- C → Spawn a ship exposes all 27 records and all 25 government records, plus independent/default choices. Spawned contacts are temporary and obey faction behavior after resuming flight. They do not change the player's ship or permanently alter traffic tables.

## Validation

- 45 fleet regression checks plus 302 existing checks pass. The existing suites isolate their fixtures from ambient combat; the fleet suite tests real source-driven population and combat.
- Source fields for ships, governments, encounters, and systems compare unchanged to the decoded original resource dump.
- A deterministic 40-second battle between eight starting capital ships launches fighters, fires live weapons, and destroys ships. Observed peaks: 17 contacts, 71 projectiles, seven simultaneous explosions. The distant neutral pilot remains unharmed, with no undeserved reputation changes.
- Visual captures: `builds/fleet-roster.png`, `fleet-sol.png`, `fleet-cheats-minimum.png`, and `fleet-panel-minimum.png`. The controls and preview fit both 1440 × 900 and minimum-size windows.
- One warmed graphical check on this Mac measured 7.869 ms for cruiser explosion creation plus explicit drawing with the 27-model roster present. This is a spot check, not a universal frame-rate guarantee or a measurement of prolonged combat performance.
