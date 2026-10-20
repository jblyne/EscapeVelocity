# Escape Velocity HD — First Flight

A playable Godot 4 prototype built around the original Escape Velocity 1.0.5 resource data. This is the first development milestone, not the complete recreation.

## Classic menu and simplified flight screen

The main menu now uses the recovered original bridge artwork, 17 mechanical button animation frames, and rotating globe sprites. Frame order and artwork come from EV Titles; playback cadence is reconstructed (15 fps for opening, 10 fps for globes), not measured original timing. `tools/extract_title_art.py` reproduces the PNGs from the local resource fork with Pillow.

The flight screen follows the original **144 × 480 instrument-panel proportions**, recreated with crisp vector bevels, green displays, a square radar, compact shield/armor/fuel bars, navigation, weapon, target scan, free cargo, and credits. The target scan uses the current 3D ship model rendered in green. Space is black with sparse parallax stars; the modern ships, planets, and hyperspace effects remain. **P** or clicking the target/cargo display opens full information; **Esc** or the small **Menu** label opens settings and controls. Clicking navigation or radar opens the map; clicking the weapon cycles it. Existing shortcuts remain available. Information screens pause flight.

Layout references: the recovered `EV Titles` PICT 128, the local original manual, and the [original flight screenshot](https://images.igdb.com/igdb/image/upload/t_720p/sckbcp.jpg). The frame geometry is reproduced at double design resolution and scales with window height. The separate armor bar, live 3D target scan, and small Info/Menu links retain modern usability.

## Forklift and cloaking

The forklift projectile now has a yellow industrial body, four wheels, overhead guard, mast, and twin forks modeled from the original PICT 230 sprite sheet. It fires with original `snd 223` (weapon Sound 23), instead of the placeholder laser. The original `snd 341` and `snd 340` play on cloak activation and deactivation. `tools/extract_special_effects.py` reproduces these WAVs from the local resource fork, preserving unsigned 8-bit mono samples and rounding the legacy fractional sample rate to the nearest Hz.

**K** toggles an installed cloaking device. For testing without the Rebel mission reward, enable **C → Cloaking device available**. This independent cheat saves with your pilot. Cloaking fades the ship and suppresses exhaust, allows weapons fire only with the cloaking-device cheat enabled while preventing enemy sensor targeting, consumes shield power and fuel, and ends on depletion. Infinite fuel works even with an empty tank. Cloaking persists through normal hyperspace and chain jumps, including partial fades; the destination model is cloaked before its first frame. Fade opacity and exhaust now ease smoothly, and retained shader variants are warmed during startup to reduce toggle hitches. Shield/fuel depletion can still end cloaking. The 1.25-second fade and faint local silhouette are a reconstruction for the 3D renderer; exact original visual timing has not been measured. Existing drain rates remain provisional. Missing equipment now produces a message instead of silently doing nothing.

## Play on this Mac

In Finder, open **builds/Escape Velocity HD.app**. Links to the `.command` launcher may open a text editor on this Mac, so launch the `.app` directly. The exported app does not need the Godot editor. To edit the project, double-click **Open Godot Project.command**.

Version **0.1.2** provides a temporary debugging reserve of **100,000 fuel (1,000 jumps)**. Press **G** any time while alive, or choose **Debug: free fuel refill** in the pause menu, to refill for free. The reserve persists in your pilot save; new pilots start with a full tank.

Version **0.1.3** makes motion visible in empty space: three star layers scroll at different rates, with brighter nearby stars and short trails as speed increases. The effect follows actual drift while coasting or turning, respects camera zoom and screen proportions, and stops during pause. No flight controls or physics changed.

Version **0.1.4** follows the original manual’s flight and navigation sequence: S/Down turns against drift, landing requires a clearance request followed by a second L, and hyperspace uses the main engines to stop, align with the destination, and accelerate before departure. Blue brackets identify the cleared world; **1–4** select a different world. **J** also cancels an active jump without spending fuel.

Version **0.1.5** matches the moving arrivals observed in the original Levo → Rigel → Levo flights. It arrives at cruise speed from the incoming-route side, with the primary planet initially off-screen at the default zoom and visible on the expanded local scanner. Without input, the shuttle passes near a central primary about 4.8 seconds later and keeps coasting. Single-hop navigation clears on arrival; use **N** or the map to select the next destination. These timings are observation-based tuning, not extracted engine constants.

Version **0.1.6** shortens the aligned spool from 4.5 seconds to **0.6 seconds** and extends departure acceleration from 2.4 seconds to **4.8 seconds**. The ship now accelerates continuously beyond normal cruise, reaching **1,650 speed (6× cruise)** before transition. The jump sound spans the whole burn. Arrival remains at normal cruise with the same approach. These departure settings follow playtest feedback rather than exact original timing.

Version **0.1.7** adds a **Cheat menu** (press **C**, click the flight HUD button, or open it from pause). Its independent toggles unlock **all 26 original weapon records with unlimited ammo** and **infinite fuel**. Pick a weapon in the menu or cycle with **Q/E**; **Space** fires and **Tab** targets a contact. Toggles and weapon selection save with the pilot. Turning weapons off restores the purchased laser loadout; turning infinite fuel off resumes consumption from the stored tank.

Version **0.1.8** adds a selected-ship panel on the right, above the radar. Press **Tab** to cycle ships and see an angled 3D preview of the actual selected model, its name/class, neutral or hostile status, live integrity, distance, and speed. Integrity reflects the existing NPC health pool. Destroying the selected contact clears the panel; destroying another ship preserves the selection.

Version **0.1.9** adds a thunder strike at hyperspace arrival: an immediate crack with a 3.2-second stereo rumble. It fires once on the system-transition tick, after the departure sound stops, and respects mute and pause. Normal startup, loading a save, and failed or canceled jumps do not trigger it.

Version **0.1.10** replaces ship-destruction spark bursts with a 3.6-second animated sequence: a bright flash, turbulent fireballs, an expanding shockwave, glowing ember trails, tumbling pieces of the destroyed ship, and fading smoke. Blasts scale with the ship model and inherit some of its motion. Effects pause with menus, clean up on system changes, and are capped at eight simultaneous explosions. Your own ship disappears on destruction; its fireball plays for 0.9 seconds before the recovery panel appears, and the remaining effects finish behind it. The last living save remains intact.

Version **0.1.11** fixes an explosion-start hitch by keeping debris shaders cached and warming explosion/flash lighting during startup. It also shares the particle plane mesh. Matched profiling reduced repeat explosion first frames from about 240 ms to about 2 ms on this Mac, with the same visual effects. Details and measurement limits are in [the performance report](research/reports/EXPLOSION_PERFORMANCE.md).

Version **0.1.12** uses the original stellar classifications and sprite proportions across all 107 objects: 75 planets, 17 mechanical stations in four styles, and 15 moons. Stardock Alpha is a station; Luna is gray cratered rock with no atmosphere; Mars is red rock. Other surfaces follow their original types. Station and moon radii are 60 and 30, with consistent landing and jump clearance. See [the original type mapping](research/reports/ORIGINAL_STELLAR_TYPES.md).

Version **0.1.13** fixes valid jumps aborting during acceleration when the departure path crosses a planet, moon, or station’s exclusion zone. Clearance is checked through the end of spooling; once acceleration starts, proximity no longer cancels the burn. Manual cancellation, pause, fuel use, and arrival behavior are unchanged. The Sol → Eridani failure and all four Sol exits are covered by regression tests.

Version **0.1.14** replaces the fixed three-ship traffic with original system encounter tables and densities. All **27 ship records** have source-informed silhouettes and original sprite proportions; the 21 ambient hulls appear in their appropriate weighted system traffic, while special ships are available through **C → Spawn a ship**. Factions, alliances, enemy fleets, civilian travel/evasion, finite NPC ammunition, carrier wings, and persistent player reputation are now active. Tab shows faction, behavior, crew, cruise speed, and current integrity. See [ships and factions](research/reports/SHIPS_AND_FACTIONS.md) for source mappings and provisional rules.

Version **0.1.15** replaces the radial hyperspace spokes with streaks drawn from the existing stars. Streaks grow along the actual travel direction during the final **2 seconds** of the departure burn. The ship stretches lengthwise to **2.8×**, then contracts, briefly squashes, and rebounds on arrival, settling in **0.65 seconds**. The animation affects appearance only; jump timing, speed, fuel, clearance, and arrival thunder are unchanged. Pause freezes the pose; cancellation and loading reset it.

Version **0.1.16** adds gentle axial rotation to all planets and moons, with a stable speed for each body (roughly 9–20 minutes per turn; moons are slower). Continents, clouds, and craters move across the globe under fixed lighting. Stations and ring assemblies stay fixed, and globe rotation pauses in menus. Ringed planets spin about their ring axis. World positions and landing boundaries are unchanged.

Version **0.1.17** refines all 27 ships with chamfered hulls and armor, framed blue canopies, recessed vents, segmented engine nacelles, faction markings, and visible gun mounts. Freighters have reinforced cargo modules; capital ships have turrets and sensors; alien ships have a ribbed carapace and luminous seams. The same geometry appears in flight and the target panel. Static parts share cached meshes grouped into hull sections, keeping rendering and destruction effects inexpensive. Ship sizes, loadouts, and flight behavior are unchanged.

Version **0.1.18** steadies normal thrust by rendering the ship and following camera from the same interpolated physics pose, with steady main-engine exhaust. A small hull vibration and pulsing exhaust occur only during hyperspace acceleration. **Tab** cycles through every ship, then **no selection**, before starting again; the empty step also clears the preview and target marker. Hyperspace departure tops out **25% faster: 7.5× cruise (2,062.5 for the shuttle)** over the same 4.8-second burn. Arrival remains at normal cruise speed.

Version **0.1.19** adds selected-ship communications: **Tab → Y** opens a portrait, faction, captain’s response, **Greetings**, **Request Assistance**, **Offer Bribe**, and **Attempt to board**. A friendly ship can rendezvous with a stranded pilot to sell one jump of fuel; payment happens on transfer. A bribe buys a ceasefire with that contact for the current system visit. **B** now boards a disabled ship when you are over it, facing within 30° of its heading and within 25 relative speed. Nonlethal damage below 15% integrity disables engines and weapons. Boarding transfers cargo, credits or fuel, respects capacity and mission cargo, applies source faction penalties, and carries an increasing self-destruct risk shown in the panel. **Esc** closes either menu; **Y** also closes communications. The debug combat drill moves to **Shift+B**. See [original communications and boarding](research/reports/ORIGINAL_SHIP_INTERACTIONS.md) for observed behavior and remaining scope.

Land at a planet or station and select **Outfitter · equipment & weapons** to buy or sell installed gear. Original outfit prices, masses, mount limits, and local technology govern purchases. Supported equipment includes weapons and ammunition, cargo/mass conversions, armor, shields, engine upgrades, fuel tanks, afterburners, and ramscoops. **Q/E** selects purchased weapons; launchers consume purchased rounds. **Shift + thrust** uses an installed afterburner. Sales return 50% of cost; loadouts persist in pilot saves. Unsupported special systems are not offered.

**Chain hyperjump:** enable it in **C**, open **M**, and select any system. The map highlights the shortest route in gold and draws a direct destination line. Return to flight and press **J** once: the first hop uses the full stop, align, spool, and acceleration sequence. Subsequent hops arrive with a boom, fly through the system for one second at retained hyperspace speed, stretch rapidly in the last quarter second, and jump instantly onward. While this cheat is enabled and you exceed 1.5× cruise speed, your wake destroys other ships within 300 distance units of your swept flight path, throughout flybys and continued high-speed coasting; captured escorts are spared. The final arrival returns to normal cruise speed. Fuel and gravity restrictions are bypassed. **J** cancels at the current stop; menus pause the countdown. Your fleet travels with you, and the toggle saves with your pilot.

Captured ships can be released with **F → Release** (also **Esc → Manage fleet**). Each released hull leaves formation as an independent friendly contact; releasing permanently removes it from the saved fleet and frees a slot. **F / Esc** closes the fleet menu.

Godot **4.7.2 stable**, its editor, and the Mac export template are in `.tools/`. Nothing needed to be installed into `/Applications`.

## First five minutes

1. You begin near Levo in a Shuttlecraft. Press **L** to request landing clearance; blue brackets mark the world. Hold **W / Up** to approach it. To slow down, hold **S / Down** until facing opposite your drift, then apply **W / Up** thrust. Turning alone does not reduce speed. Your ship’s center must be over the planet and its speed **25 or less** before a second **L** lands. The HUD guides each step.
2. At the port, accept the courier contract. You can also buy/sell cargo, refuel/repair, or buy another laser cannon.
3. Press **L** to launch. The contract sets your navigation destination. Fly away from the planet until the navigation panel says **Clear to jump**, then press **J**. You need **500 km beyond the edge of every planet or station**. The panel shows the remaining clearance. The computer turns against drift and uses the main engines to stop, aligns with the selected galaxy-map connection, spools for 0.6 seconds, then accelerates continuously for 4.8 seconds to 7.5 times cruise speed. A turnaround from opposite full-speed drift takes about 7.6 seconds; other starting headings and speeds change the preliminary maneuver. Drifting back inside the clearance limit while stopping, aligning, or spooling cancels the jump without using fuel. Once the final acceleration begins, crossing that limit no longer cancels the departure. **J** cancels manually; momentum is preserved, including excess speed during the departure burn. Turn against drift and use main-engine thrust to brake. **M** opens the galaxy chart.
4. You arrive moving at cruise speed toward the primary world. Begin braking on approach; the ship will otherwise fly past it about five seconds after arrival. Request clearance with **L**, fly over the destination world, slow to 25 or less, and press **L** again. Use **1–4** to select a specific world in systems with multiple destinations. Clearance for one world cannot be used at another. The delivery pays automatically, once.
5. In space, press **Shift+B** to spawn a hostile Defender for a combat drill. **Space** fires and **Tab** cycles contacts. Neutral traffic will defend itself if attacked.

## Controls

| Key | Action |
| --- | --- |
| W / Up | Thrust |
| A / D or Left / Right | Turn |
| S / Down | Face opposite drift; then use W / Up thrust to slow down |
| Space | Fire selected weapon |
| Q / E | Previous / next weapon while the weapons cheat is on |
| C | Open / close cheat menu (weapons, infinite fuel, Invincibility, Deflection) |
| Tab | Cycle contacts → no selection → first contact; show selected ship preview / information |
| L | Request landing clearance / land on the next press / launch |
| 1–4 | Select a landing world (L requests its clearance) |
| M | Open / close galaxy chart |
| N | Cycle connected jump destinations |
| J | Stop, align, spool, accelerate into hyperspace / cancel |
| Y | Hail selected ship / close communications |
| B | Attempt to board selected disabled ship |
| Shift+B | Spawn a combat-drill enemy |
| G | Free debugging fuel refill (1,000 jumps) |
| Mouse wheel | Zoom |
| F5 / F9 | Save / load |
| V | Toggle sound |
| F11 | Toggle fullscreen |
| Escape | Pause / resume or close a screen |

On keyboards that use function keys for system controls, hold **Fn** to access F5/F9/F11. Save/load and sound controls are also in the pause menu.

Progress saves automatically when landing, purchasing, completing a jump, periodically in flight, and on a normal quit. A destroyed ship does not replace the last living save. The save is `pilot-v1.json` in Godot's application-data folder for `Escape Velocity HD — First Flight`.

## Implemented in this build

- Import of the original 108-system, 139-link galaxy network; every system can be visited through its connected routes.
- Original system/world names and coordinates, plus ship and weapon fields used as the initial tuning inputs.
- Overhead 3D flight, distinct procedural ship models based on the original silhouettes, classified planets/moons/stations, target markers, radar, zoom, and a galaxy chart.
- System-specific weighted traffic and population from the original encounter data. Ships enter and leave; military enemies engage each other; merchants travel and evade threats. NPC flight, health, installed weapons, and ammunition use their ship records. Carrier wings and debug fighter bays use the correct fighter models. Faction names and colors appear in the scanner and target panel. Ship attack/kill penalties persist in pilot reputation and can make a government hostile; allied military contacts respond to attacks.
- Ship combat, player shields/armor, varied traffic, a summonable hostile, and destruction effects. The cheat arsenal adds bolts, aimed turrets, guided missiles and torpedoes, rockets, proximity bombs, particle/fusion beams, tractor pull, decoy flares, six fighter-bay types, and the hidden Forklift. Unlimited ammo preserves reload timing. Up to 12 debug escorts can be active; a new launch replaces the oldest at that limit.
- Selected-ship hailing, greetings, paid rescue refueling, contact-specific bribery, disabling, and boarding for cargo, credit and fuel salvage. Disabled ships can also be captured by their boarding party and, on a successful attempt, join a persistent fleet that follows the player between systems.
- Landing, six trade commodities, refuel/repair, an introductory courier contract, and two purchasable additional laser cannons.
- Per-world landing clearance, selection brackets, and docking restricted to the visible planet disk and low speed. Hyperspace stops with main-engine thrust, aligns with the warp line, spools, and accelerates before departure; clearance from every world is checked until the departure burn begins. Arrival follows the incoming route at cruise speed, with an approximately five-second coast toward the primary. Live HUD guidance explains each stage and blocked travel.
- Versioned pilot saves, validation of loaded state, atomic save replacement, and pause controls.
- Seven original synthesized sounds, including the stereo thunderclap on hyperspace arrival.

## Fidelity and scope

The resource importer preserves the original data. **Gameplay behavior is still provisional.** Acceleration/time conversions, turn rates, AI movement/target selection, projectile lifetime, recharge, landing thresholds, travel timing/fuel cost, market variation, services, and upgrade effects are newly implemented prototype rules, not verified translations of the original engine. Flight conversions are isolated in `godot/scripts/flight.gd`; the jump sequence is in `godot/scripts/hyperspace.gd`. Version **0.1.4** implements the documented retrograde-turn, landing-clearance, and stop/align/accelerate sequence; version **0.1.5** tunes the jump and arrival to two observed original-game flights, documented in [the reference observations](research/reports/ORIGINAL_HYPERSPACE_OBSERVATION.md). The different camera scale is retained: 275 world units/second and a 1,320-unit approach preserve the observed time to the planet, rather than copying original screen pixels. Entry into offset and multi-world systems is an unverified extension that stays outside every gravity exclusion area. Exact engine parity remains unverified. Faction-based landing refusals are implemented; mission-based faction allegiance is now persistent. Version **0.1.1** tightens landing and hyperspace based on playtest feedback; its speed limit of 25 and surface clearance of 500 are adjustable in `godot/scripts/travel_rules.gd`, not values recovered from the original executable. Existing pilot saves remain compatible.

The test Shuttlecraft starts with one loaned laser cannon and 10,000 credits to make the build useful immediately. The courier contract is authored for the prototype. All 116 original mission definitions now feed the mission computer and bar engine, including prerequisite bits, original briefings, cargo stages, encounter objectives, deadlines, faction rewards, and special equipment grants. Ship purchasing and military clearance, capture, and persistent captured escorts are implemented. Exact original-game parity and old add-on compatibility remain incomplete; see the [fidelity checklist](research/reports/ORIGINAL_MISSION_PROGRESS.md). Cheat weapon guidance, damage against the prototype’s single NPC health pool, beam range, explosions, and escort behavior are provisional. Weapons use the imported names and rate/damage fields with existing sounds. NPC ships now use their installed loadouts, bounded firing rates, finite missile ammunition, and carrier wings; their durability remains a combined shield-plus-armor integrity pool. Debug escorts attack the selected contact or nearby hostiles; they are cleared on system changes and when disabling the weapon cheat. They are not the original persistent escort system. Stellar models now follow original planet/station/moon types; their modern geometry and surface details are new artwork informed by the original sprites. Ship art now follows all 27 original records, using modern procedural geometry informed by the decoded sprites. Exact material detail and original AI behavior are still provisional; mission encounters now spawn from the source definitions, while detailed original AI timing remains provisional.

Next: improve fidelity through original-engine analysis and reference play, verify complete campaign playthroughs, and replace the prototype models/audio with a coherent final art direction.

## Development and validation

Run commands from this folder:

```sh
python3 tools/build_catalog.py
python3 tools/generate_audio.py
python3 -m unittest discover -s tools -p 'test_*.py' -v
.tools/Godot.app/Contents/MacOS/Godot --headless --path godot --script tests/test_game.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path godot --script tests/test_cheats.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path godot --script tests/test_target_panel.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path godot --script tests/test_ship_interactions.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path godot --script tests/test_arrival_audio.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path godot --script tests/test_explosions.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path godot --script tests/test_stellar_types.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path godot --script tests/test_hyperspace_departure.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path godot --script tests/test_fleets.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path godot --script tests/test_jump_visuals.gd
.tools/Godot.app/Contents/MacOS/Godot --headless --path godot --export-release macOS '../builds/Escape Velocity HD.app'
```

The exporter currently records the local Mac template's absolute path in `godot/export_presets.cfg`; update it if moving this checkout. Rebuilding the catalog requires the local original resource dump under `research/decoded/`.

Validated on this Mac with **435 Godot gameplay/cheat/target/audio/explosion/stellar/departure/fleet/visual checks and 7 Python resource-reader tests**, plus visual inspection of flight, galaxy-map, and port screens. The Godot tests use their own temporary pilot save in `builds/`. They cover the full delivery loop, connected travel, fuel, trading limits, save/load, projectile hits, and frame-rate consistency of the provisional flight model. Landing and hyperspace checks cover both sides of their boundaries, differently sized and multiple bodies, prohibited docking/jumping, HUD feedback, and charge cancellation without fuel loss. Fuel checks include old-save compatibility and a free debugging refill that preserves other progress. New checks verify drift-preserving retrograde steering; engine braking, stopping, alignment, and directional acceleration at 30/60/120 Hz; per-world clearance; cancellation, pause, destination locking, and navigation-state reset on arrival/load. Arrival checks cover both directions of the Levo/Rigel trip, steady hands-off coasting, time to the primary, safe entry along every connected catalog route, empty and offset systems, and cleared navigation/map behavior. Departure checks verify a short spool, continuous acceleration to 7.5 times cruise speed, consistent travel distance at 30/60/120 Hz, pause, cancellation at high speed, and gradual main-engine braking afterward. The full-speed turnaround takes about 7.6 seconds in this build. The 55 ship-interaction checks cover keyboard and actual menu actions, pause/target safety, assistance with an actual rendezvous, prices and ceasefires, disabling and boarding requirements, bounded salvage transfers, repeated-action protection, save validation, source reputation penalties, and self-destruction. The 66 cheat checks cover all 26 usable weapons, repeated ammo-free launches, actual empty-tank hyperspace, both menu toggles, old-save compatibility, strict save validation, turning cheats off, missile guidance, turret aim, beam hits, tractor pull, area damage, flare diversion, and escort launches/firing/limits. The 22 target-panel checks cover real Tab input, matching preview geometry, separation from the world ship, cached rendering, live information, neutral/hostile states, destroyed targets, stable selection when other ships are removed, pause, reload, and empty systems. Visual review covers neutral and hostile previews at normal and minimum window sizes. The 13 arrival-audio checks verify same-tick playback, no premature or repeated strike, departure audio stopping, pause/resume, mute, save loading, and failed/canceled jumps. The 25 explosion checks cover lethal versus nonlethal damage, moving debris, frame-rate consistency, pause/resume, cleanup, bounded effect counts, player destruction, recovery-panel timing, living-save preservation, and independent fading with cached shaders. Visual captures inspect the flash, fireball, smoke, debris, and player-death phases. The 15 stellar checks cover source classification, model selection, station docking, moon landing, and save compatibility. The 49 departure regression checks reproduce the reported Sol crossing, exercise all four Sol connections at 30/60/120 Hz and a late-burn crossing, verify saved arrival/fuel/speed, and retain exclusion checks throughout preparation. The 47 fleet checks cover every system’s eligible ships, all models and sizes, faction relationships, NPC weapons and ammunition, crime persistence and save compatibility, real debug-menu controls, bounded carrier wings, traffic lifecycle, and a 40-second autonomous carrier battle. Two geometry checks preserve mixed indexed/unindexed triangles, transforms, and independent exhaust when batching details. Other feature tests use isolated contacts to avoid dependence on randomized ambient combat. The 28 jump-visual checks cover delayed buildup, ship-local stretching, arrival continuity, squash/rebound, frame-rate consistency, pause, cancellation, load/death cleanup, and unchanged flight state. Graphical captures inspect early/late acceleration and four arrival poses. Normal-thrust checks verify steady exhaust, no ordinary hull vibration, smooth render movement between physics ticks, shortest-path steering interpolation, and clean transition resets. Target checks include the empty-selection step and one-ship cycling. A rendered 120 Hz control check held normal cruise to a 0.009-pixel screen-position spread over 181 sampled frames and observed a 2,062.498 departure peak followed by 275 arrival speed. These checks do not establish numerical parity with the original executable.

Original-game extraction findings are in [research/reports/ORIGINAL_GAME_ANALYSIS.md](research/reports/ORIGINAL_GAME_ANALYSIS.md). Engine and content acknowledgements are in [godot/CREDITS.md](godot/CREDITS.md).

Hold **T** to turn toward your selected ship while flying or firing. If no ship is selected, it faces your selected landing destination. Release T to stop tracking; manual turns and retrograde steering take priority. This adapts the original hold-A alignment control while preserving this version’s WASD steering.

**Cap’n Hector:** the original Rapier pilot occasionally visits during ordinary flight with a shareware reminder on the main screen. First visit: about 3–6 minutes; later visits: 6–10 minutes apart. This is a nostalgic cameo, with no actual registration or payment requirement.


Mission and ship progression update: **I** opens the mission journal in flight or the mission computer/bar when landed. Offers depend on location, legal/combat record, prior mission flags, and a stable random roll per system visit. Up to eight missions can be active. **K** toggles an installed cloak; it drains shield power and fuel, allows firing only with the cloaking-device cheat enabled, and prevents targeting/scans. Special Ops Insertion grants the cloak on acceptance. The stolen particle-beam and Astrodyne chains award the particle beam and tractor beam. Military mission clearances unlock local military stock. Shipyards offer original hulls, stock weapons/ammunition, and 25% trade-in credit; special mission equipment transfers. Saves retain the hull, active objectives, and campaign progress.

Player projectiles approaching a predicted lethal direct impact trigger a short spoken panic reaction from the threatened ship. Prediction includes target drift, first-contact obstruction, remaining projectile lifetime, and health; evasive movement can still avert impact. Cries are limited to nearby combat and once per ship, do not overlap each other, and respect mute/pause. Twenty-four commander takes use Harry, George, Callum, and Charlie, with clipped orders and gruff/strained delivery directions. Each human faction pool includes two voices and eight takes; Alien ships retain their separate two-take pool. Earlier Roger/Jessica human warning clips are archived and no longer selected. Recordings retain their natural pitch and timing with no radio filtering. A shuffled selection plays every take before repeating and prevents back-to-back duplicate takes. Reimport the archived recordings on macOS with `python3 tools/generate_panic_audio.py`.

Faction panic update: warnings begin up to 3 seconds before a predicted lethal direct hit (within 2,200 units of the projectile and 2,600 units of the player). The speaking ship owns its transmission: its explosion cuts the voice off in the same frame; unrelated explosions do not. Despawning and system changes also clear the voice. Twenty-six saved ElevenLabs warning performances are divided into civilian/independent, Confederation, Rebel, Pirate, and Alien pools, each with its own shuffled rotation. Confederation and Rebel government variants share their parent faction’s pool; other local governments and shipping corporations use the civilian pool.

Every ship explosion now plays a 0.85-second fading scream, including the player and launched ship hulls. Small crews use a single voice; ships with at least six crew use three overlapping voices; ships with at least 100 crew or 300 mass use six. Alien ships use separate layered vocalizations. Same-frame explosions can overlap, with eight playback slots per effect; group recordings are normalized to avoid multiplying volume. Mute and pause still apply, while the player’s final cry remains audible on the death screen. Rebuild group assets with `python3 tools/mix_crew_screams.py` after importing the source recordings.

Ship explosions use the original `EV Sounds` `snd ` 303 (`ShipExplodes`) recording. Weapon blasts use `snd ` 300 (`HeavyExplosion`). The source unsigned 8-bit PCM is preserved byte-for-byte at the rounded original 11,127 Hz rate, without resynthesis or pitch changes. Crew screams remain layered over ship explosions. Re-extract with `python3 tools/extract_special_effects.py`.

Explosion mix: the loud original ship and heavy-blast samples play at -24 dB and -26 dB respectively, with at most three overlapping instances each, leaving room for weapon, engine, and voice effects. Source audio remains unchanged.

Additional last words: each human faction has one new urgent order and one gallows-humor line, recorded with its established commander voice. Civilian: “I just paid this thing off!” / “Mayday! Hull breach! Get out!” Rebel: “Who put the rookie at the helm?!” / “Abandon ship! I will cover you!” Confederation: “This is NOT in the manual!” / “Reactor critical! All hands, eject!” Pirate: “I demand a refund on these shields!” / “Forget the loot! Get to the pods!” The existing shuffled rotations, impact cutoff, and balanced explosion mix apply.

Death scream variety: six human solo takes (Adam, Callum, Harry), three alien solo takes, and three different mixes for each human/alien crew size. Each pool uses a shuffled rotation with no consecutive repeat, including at shuffle boundaries. All 21 effects retain the 0.85-second fade and normalized group levels.

Split-hull destruction: 28% of ship losses use two complementary halves cut from the actual hull meshes, capped with glowing fracture surfaces. The halves drift and tumble with fire/smoke for 2.2–3.2 seconds before the first detonation; the other half follows 1.0–1.7 seconds later. Either half can go first. Each uses the original explosion sample at the balanced volume; the original death scream plays once. Wreck blasts are visual only, respect the shared pause/death-screen clock, and clean up on expiry or system changes. `test_breakup.gd` covers the staggered sequence and `capture_breakup.gd` renders its stages.

Burning wreck audio: each split half owns a separate six-second looping crew mix. Human halves begin with different Harry/Callum performances of “This is the end!” and “Oh nooooo!” over layered screams; alien halves use alien cries. Each player stops in the same simulation update as its own detonation, while the survivor continues. Pause freezes playback, mute silences it immediately, and world/effect cleanup frees the owned players. Both mixes play at -10 dB to control their combined volume. Rebuild with `python3 tools/mix_wreck_audio.py` after importing the voice sources.


## Fleet management and normal fuel

Press **F** for Defend, Attack, Hold, Recall and Release. At a port, the same screen offers hired captains, daily wages, and paid repairs/rearming. Captured escorts now fight with their original hull loadouts, consume ammunition, take damage and can be permanently destroyed. **Take command** transfers you into a captured ship after a confirmation; your old hull/equipment are abandoned and cargo must fit.

Fuel capacity now follows each original ship's tank. Existing testing saves migrate safely; infinite-fuel and chain-jump cheats remain available. Combat now tracks shield and armor separately and uses the original-EV damage conversion documented by SpacePort. See [fleet/combat update and fidelity limits](research/reports/ORIGINAL_FLEET_AND_COMBAT.md).

## Original-game completion stages — 19 October 2026

Stage 1 adds shared **commodity** capacity across persistent escorts and ammunition salvage. Trade purchases and boarding cargo fill your own hold first, then escort holds; port sales draw from escorts first. Mission freight stays on your flagship. Each escort's manifest saves independently and leaves your fleet with that ship on destruction, release or unpaid departure. The fleet screen displays its freight; taking command requires room for both ships' retained cargo.

Board a disabled ship and choose **Take Ammo** to recover finite rounds compatible with installed launchers. Equipment space and installation limits apply, donor magazines decrease, and the usual transfer self-destruct risk applies. **H already hails worlds** for landing status and tribute.

The remaining controls/pilot-mode, exploration, economy, secret/add-on and original-executable verification work is staged in [the implementation plan](research/reports/IMPLEMENTATION_STAGES.md). Freight allocation and salvage limits are remake rules pending exact original comparison.

## World-killer — Death Star ultimatum

In flight, select an inhabited planet with **1–4**, press **H**, and choose **Threaten with world-killer → Deploy world-killer**. The experimental launcher now summons a **Death Star**, with one active ultimatum at a time. Some planetary authorities answer rudely; threats are also available against polite worlds. Stations and uninhabited worlds cannot receive an ultimatum.

The countdown starts immediately at **02:00**. The armored spherical station arrives at a distance with the normal ship arrival snap and thunder, settling in **0.65 seconds**, then slowly approaches the planet. It leaves a **200-unit surface gap** at its firing position. At **00:20** it stops beside the surface. After a five-second hold, its recessed dish begins charging at **00:15**: eight green emitter beams snap into the focus in a rapid stagger. Each reaches the focus in **180 milliseconds**, and all eight converge over roughly **1.7 seconds**. A low reactor rumble and soft energy swells replace the sharp electronic chirps. Fast energy packets, layered neon halos and a pulsing starburst build energy for the remaining charge time. At **00:04** the merged superlaser fires into the planet, lighting the impact and spreading glowing fractures. At zero, the existing fourteen-second molten-crust, fire, smoke and shockwave effect obliterates the world. The Death Star then turns away for two seconds, flies away slowly for twelve seconds, then uses the player’s actual stop, align, spool and 4.8-second acceleration sequence, including the final ship stretch. It physically accelerates thousands of units away using the player ship’s flight capabilities. Recalls use the same withdrawal sequence.

Twelve seconds into the countdown, planetary control hails to plead for mercy. **Accept appeal** cancels the laser and recalls the station; **Reject appeal and bribe** continues the countdown and gives planetary control a chance to raise its offer. Click the status banner to reconsider before detonation, even after firing begins. Menus pause the countdown, station, beam sequence, withdrawal and audio; flight in other systems still advances the attack. Saves retain the full sequence. Existing deployed missiles and earlier Death Star saves migrate to the revised sequence and wider spacing with their remaining time and mercy/refusal state preserved.

The station has a paneled hull, an equatorial trench, a recessed superlaser dish, the normal ship warp effect, eight visible converging feeds, a main beam and a planetary impact glow. Normal ship arrival/departure sounds and dedicated synthesized charge and firing effects accompany the sequence; regenerate the synthesized effects with `python3 tools/generate_world_killer_audio.py`. The synthesized effects are new sounds for the remake.

Destruction persists in that pilot's save: the world loses landing facilities, gravity exclusion, tribute and local events; contracts requiring it fail normally. Its government records the attack and news reports the loss. New mission offers, courier destinations and escape-pod rescues avoid destroyed ports. A deterministic debris field replaces the planet on return or reload. Surviving stations and moons remain intact.

`godot/tests/test_world_killer.gd` covers the complete timing, eight-beam convergence, impact, mercy during firing, departure, audio/mute/pause, save migration, remote attack, persistent destruction and original mission cleanup. Run with `-- --visual` to capture the sequence, and add `--small` for minimum-window checks.

## Physical ship departures — version 0.1.24

Ambient NPC departures, named-character and mission retreats, and Hector now use the same hyperspace engine as the player. They clear planetary gravity, stop, align with a connected destination, spool and accelerate before being removed. Fleet escorts stay with the player; disabled ships cancel departure and remain available to board. Escape pods and ships landing on a planet retain their separate cleanup behavior. Jump audio respects pause and mute.

`godot/tests/test_ship_departures.gd` compares movement against the player frame by frame at 30, 60 and 120 Hz and checks NPC lifecycle, gravity clearance, pause, disabling, fleet protection and the Death Star’s completed withdrawal. Run with `-- --visual` for a departure capture. Mission, fleet and Hector tests now wait for actual jump completion before expecting removal.

## Main-menu animation and original audio — 19 October 2026

The opening panels now use their registered left/right artwork positions throughout the animation and retain the final mechanical frame. Each button's own label fades into its face without replacing the pistons or rails; clickable areas follow the same rectangles. Adjacent original frames blend at the render rate, and opening a pilot preserves the menu instead of replaying its entrance.

The menu plays the recovered **MachineHum** (`EV Sounds`, `snd ` 601) during extension, **Slam** (602) when the panels lock, **Click** (600) on buttons, and **Title Music** (`EV Music`, 30000) on entry. PCM samples are unchanged, with only Sound Manager's fractional sample rate rounded for WAV. The title recording plays once, as exported without a looping region. Mute stops menu audio immediately; unmute resumes the title recording, and entering flight stops the music and mechanical effects. Animation and sound cue timing remain remake reconstructions.

Re-extract with `python3 tools/extract_menu_audio.py`. Validation: `test_menu_presentation.gd` covers frame blending, registered button bounds, audio lifecycle, pilot-menu continuity and a rendered comparison across the final-frame transition; `tools/test_menu_audio.py` verifies delivered samples byte-for-byte against the original resource forks.


## Original star map — version 0.1.26

The map now follows the original manual’s PICT 2008 layout: square chart at left, government/legal/market/service details at right, ports and navigation hazards below, and grey **−**, **+**, **Clear Route** and **Done** controls along the bottom. It opens centered on your system at a local-neighborhood zoom, rather than fitting the whole galaxy. Drag empty space to pan, use the wheel or +/− to zoom, and press **C** to recenter. **Tab**, **Backslash** and **N** cycle connected destinations. Remote systems can be inspected without changing your next jump. Green brackets mark the selection; a blue center marks your current system. System colors distinguish unexplored, uninhabited, friendly and hostile locations.

Accepted campaign missions and the introductory courier contract have **red arrows**, including directional arrows at the chart edge for distant targets. Prospective mission briefings have a **Show destination on map** button (or **M**) with a **green arrow**; Done returns to that briefing. Source flags that suppress accepted mission arrows remain respected. Unknown destinations do not expose service details. The market and service lists describe the remake’s current trading/outfitting rules; they do not establish original commodity-price or landing-history parity.

**Shift-click** connected systems in order to plan a route. Each normal jump selects the next stop and waits for **J**; Clear Route removes the plan. The existing chain-jump cheat retains automatic travel. Routes are transient and clear on save loading or restarting. `test_map_screen.gd` checks controls, real keyboard input, zoom/pan, mission markers, offer return behavior and an actual fueled arrival along a planned route. Its `-- --visual` captures normal and small-window layouts. See `research/reports/ORIGINAL_MAP_SCREEN.md` for the reference evidence.


## Death Star bribe negotiations — version 0.1.27

The first planetary appeal now includes an **Accept bribe** option showing the exact credit amount. Accepting transfers those credits once, cancels the attack even during firing, and starts the same physical Death Star withdrawal as mercy. **Accept appeal** still spares the world for free.

Initial offers vary with a random treasury contribution and the target’s technology level. Rejecting schedules a higher counteroffer after **8–18 seconds of flight time**. The increase varies each round, with additional urgency as detonation approaches. Improved offers set the incoming-hail banner and notify the player without forcing another menu open. Click the banner to negotiate again. Closing or reopening the channel does not reroll the offer; pausing freezes both the countdown and the counteroffer delay. Negotiation never resets the two-minute timer.

Offers, negotiation rounds and scheduled counteroffers persist in saves; older active attacks migrate to a stable offer. Payout and recall are saved together. `test_world_killer_bribes.gd` covers varied escalation, real disk reloads, pause, stale/wrong-channel actions, validated legacy saves, exact one-time payment, final-laser recall, free mercy and destruction. Its `-- --visual` captures the bribe screen. The original world-killer and physical-departure suites also pass.

## Classic landing screens and regenerated scenery — version 0.1.28

Landing now follows the original layout: large scenery at left, the original world description at upper right, compact grey service buttons below it, Mission Computer beneath the picture and Leave at lower right. It scales to the window, and descriptions wrap inside their column. The original 333:271 scenery proportions are preserved.

All **36 original scenery pictures** have new high-resolution interpretations generated from their originals: 34 type landscapes and two custom station/planet views. Their compositions and distinctive colors remain recognizable. All 91 landable ports use their original Type/CustPicID mapping, including Stardock Alpha, Luna and Darkstar. Assets are in `godot/assets/landing`; exact prompts are in `research/reports/LANDING_ART_PROMPTS.json`.

Commodity Exchange now opens separately with a green selected row, fleet cargo quantities, prices and Buy/Sell controls for up to ten tonnes. Spaceport Bar leads to bar offers, news/tribute and fleet services. The introductory courier contract is available in Mission Computer. Existing refueling/repair, outfitter, shipyard, fleet cargo, pricing and save behavior are retained. Escape backs out of a service before launching.

`test_port_presentation.gd -- --assets` checks all port artwork/text and service flows; `-- --visual --assets` captures normal and small-window layouts. See `research/reports/ORIGINAL_LANDING_SCREENS.md` for references, asset provenance and verification details. The macOS bundle and project both report version 0.1.28.


## Classic mission computer and outfitter — version 0.1.29

The mission computer now follows the original manual’s PICT 2012: compact black dialog, scrollable list at left with a green selected row, original offer text at right, and grey **Leave / Accept Mission** buttons below. Clicking a row immediately shows its briefing. The introductory courier is a normal row in the list. **M** still opens the selected destination’s map and returns to the same briefing. The active journal follows PICT 2013 with **Abort Mission / Done** controls; **I** opens it from flight or port, including accepted courier contracts. Mission computer and spaceport-bar offers remain separate entry points on the port screen. Acceptance reports remain in the briefing pane until another row is selected.

The outfitter now follows PICT 2016: four compact columns of equipment, small installed/ammunition counts, green selection frame, original item description at upper right, price/balance/free-space readouts, a larger selected-item preview, and grey **Buy / Sell / Leave** controls. Existing 3D equipment artwork is retained against black backgrounds. Selecting an item preserves the grid and scroll position. The large category tabs and cards are removed; the full catalog remains scrollable, with existing technology, equipment-space and mission restrictions enforced by Buy/Sell.

Both dialogs retain their compact design sizes on large windows and shrink to fit smaller ones. Existing mission interpretation, prices, stock, equipment effects and save rules remain unchanged. `test_classic_services.gd -- --visual` checks the mission/map/accept/abort/courier flow, equipment selection and transactions, and captures normal and small-window layouts. Mission, map, landing, outfitter and base gameplay regressions pass. References and implementation details are recorded in `research/reports/ORIGINAL_SERVICE_SCREENS.md`.


## Outward planetary debris — version 0.1.30

Planetary crust fragments now retain their launch speed instead of exponentially slowing down. The 28 long-lived remains also launch radially outward at varied speeds and tumble continuously; they no longer form a static ring beside the old planet. Their size stays constant and they keep moving until the player leaves the system, with normal camera culling as they disperse. Menus pause their motion. Reentering a destroyed system reconstructs the same seeded, outward-moving remains; the existing destroyed-world save format is unchanged.

`test_planet_debris.gd` checks all launch directions, constant speed, tumbling, stable fragment size, frame-rate agreement at 30/60/120 Hz, actual detonation, continued motion after blast cleanup, pause, reload and system cleanup. The full Death Star sequence and bribe regressions also pass.


## Classic mission messages — version 0.1.31

Landing mission reports now follow original manual PICT 2019: a compact black dialog with a thin grey frame, plain original narrative and a grey Okay button at bottom right. Long narratives scroll within the dialog. The reward summary remains available on the button tooltip; mission rewards, report queues and Escape behavior are retained.


## Compact port services — version 0.1.32

Commodity Exchange and Spaceport Bar now share the outfitter’s 1000 × 530 display size, centered without growing on large windows. Both shrink to fit small windows and retain their existing layout and controls. The landing scenery screen keeps its existing size.


## Classic escort hiring and Holo-Vid — version 0.1.33

Fleet management/escort hiring and Galactic News now use centered 1000 × 530 black dialogs, thin grey borders, plain text and grey buttons matching the outfitter. Scrollable contents keep long fleets, hiring lists and news accessible while Leave stays visible. Both fit smaller windows. Hiring, wages, orders, repairs, flagship transfers, news and tribute behavior are retained. Fleet management (35 checks) and world activity (38 checks) pass.


## New Bavaria visuals — version 0.1.34

Ice worlds now have irregular polar frost boundaries and rougher, nonmetallic surfaces instead of broad smooth caps. Atmosphere shells no longer cast shadows. Landing artwork is explicitly preloaded with a fallback for unknown picture IDs, keeping all scenery as export dependencies. New Bavaria retains its original type-12 snowy mountain landscape.


## Classic shipyard — version 0.1.35

Shipyard now matches the compact 1000 × 530 port dialogs: black panel, grey frame, green selected ship list, rendered ship preview, specifications, credits, trade-in price and grey Buy Ship/Leave controls. Selection persists across purchases; restrictions and stock equipment transfers retain existing rules. Shipyard regression and presentation checks pass.


## Shattered-world map markers — version 0.1.36

Systems containing destroyed planets show an orange broken ring with outward fragments, alongside normal ownership, selection, route and mission markers. Selected-system details name the shattered worlds; a chart legend explains the marker. Markers derive from saved destruction state, and known destroyed systems remain chart-visible without revealing unrelated systems. Map regression and presentation checks pass (34 checks).


## World-killer station threats — version 0.1.37

Inhabited space stations can now receive world-killer threats, deployment, appeals, escalating bribes and mercy. Station targets use the same countdown and Death Star departure but explode into hull sections and outward-moving metal wreckage instead of planetary crust. Active and destroyed station states validate and persist; destroyed stations lose docking/services and appear on the destruction map overlay. Planetary behavior remains covered by existing regressions.


## Directional chain-jump arrivals — version 0.1.38

Chain jumps now retain the normal upstream arrival point rather than replacing it with a fixed position below the primary planet. The destination stays ahead along the incoming heading, with the same approach distance and gravity clearance as normal jumps. Intermediate chain hops retain their existing burn speed; final arrivals use cruise speed. Chain jump checks (40) and base gameplay/arrival geometry checks (115) pass.


## Classic planetary hails — version 0.1.39

Planet and station hails now share the compact black/grey port dialog styling, plain control messages, concise grey action buttons and a persistent Close Channel control. Long messages and appeal options scroll within the panel. Tribute, world-killer deployment, mercy, bribes and channel behavior retain their existing rules.


## Original weapon sounds — version 0.1.40

All source weapons now play the original EV Sounds recording selected by their weapon Sound field (snd resource 200 + Sound), including laser variants, neutron/proton guns, mass drivers, torpedoes, missiles, rockets, bombs, beams, drones, decoys, fighter bays and forklift. `tools/extract_weapon_audio.py` preserves the original unsigned 8-bit mono PCM without synthesis or resampling. All 18 distinct WAV payloads were verified byte-for-byte against their resource data. Firing audio now lives in Arsenal so player and NPC shots share the same mappings; the old generic player-only firing sound is removed. Beam ticks sustain their sample, distant shots attenuate, and mute/menu pause/system cleanup apply to the new channels. `test_weapon_audio.gd` checks every weapon mapping and sample plus player/NPC firing, beam playback, mute and distant-fire suppression.


## Fear and landing clearance — version 0.1.41

Ports now weigh fear against resolve when considering landing. Destroying a planet adds 40 fear; destroying a station adds 20. Each destruction in the same system adds 25, and a shared explicit government adds 15. Fear caps at 100; resolve ranges from 40 to 80 with technology level. Intimidated inhabited ports waive legal/reputation landing requirements and offer submissive hail responses. Hails display the fear score and stance. Active sieges, absent facilities and destroyed targets still prevent landing. Fear derives from existing saved destruction history, so it is stable across reloads without new save fields.


## Live Death Star appeals and evacuations — version 0.1.42

Incoming appeals no longer open a modal or pause flight. A bottom-left transmission panel exposes the current offer, Accept/Deny and free mercy controls while the countdown continues. Refusals retain varied, increasing counteroffers; stale/double actions cannot collect payments. Four randomly selected, saved personalities use 48 lines across haughty, anxious, desperate and begging stages, avoiding consecutive repeats. During desperate stages, targets sometimes launch fireworks whose glowing dots converge into apologies and mercy pleas.

During the final 45 seconds, planets and stations launch a civilian transport roughly every five seconds, subject to the existing contact cap. These named refugee ships carry displayed passenger counts, have no weapons, and use normal NPC departure flight to clear gravity and warp away. Broadcasts and evacuation launches are local to the threatened system; intentional menus still pause simulation. Existing attack saves migrate without resetting the timer. `test_live_appeals.gd -- --visual` checks live actions, continued time, personalities, station/planet evacuations, real transport movement, fireworks, payout safety and intentional pause.


## Persistent interaction memories — version 0.1.43

Pilot saves now retain per-contact action counters, latest action and campaign day. Tracked actions include hails, assistance requests, completed refueling, bribe offers/payments, boarding, plundering, capture, tribute demands/releases, world-killer threats, rejected appeals, mercy and accepted planetary bribes. Requests remain distinct from successful transfers. Repeat greetings recall the relevant action and its count while retaining existing story/fear responses.

Worlds/stations use object IDs; named captains use person IDs across encounters. Anonymous captains receive individual IDs, so unrelated ships of the same model never inherit memories. Their history follows the live contact; a newly generated anonymous ship is a different captain. History stores at most 2,048 contacts, preferentially retiring the oldest anonymous records while preserving named/world histories. Old saves migrate to empty history; malformed counters are rejected. `test_interaction_history.gd` covers identity, all counters, dialogue, JSON and real disk reloads, legacy compatibility, invalid counts and actual assistance/bribe/world interactions.

## Original parity expansion — version 0.1.44

Keyboard & Game Speed is now available in title preferences and pause settings: saved bindings, conflict checks, defaults, a classic flight preset, adjustable simulation speed and Caps Lock acceleration. New Pilot supports a name and strict play. Strict destruction permanently marks that pilot's save deceased; normal saves and escape-pod survival keep their previous behavior.

Markets use original commodity flags and recovered default price arithmetic instead of port-ID prices. Unavailable goods cannot be traded, source events override the affected price, and market/service displays respect source availability. Source asteroid density creates missile/laser cover; scanner interference affects remote radar. Map service and hazard information now reflects those fields.

S+O+L restores the recovered Satellite of Love shipyard preview and X opens the original title haikus. The secret uses original art and prose without fabricating a new ship's statistics. Add-on support is excluded. Exact original timing/balance, some economy formulas and manual campaign verification remain open; see [the evidence and scope report](research/reports/PARITY_EXPANSION_2026-10-19.md).

## Original service and recovery rules — version 0.1.45

Equipment now uses original technology discounts, price rounding, 80% existing-equipment resale, and same-visit purchase refunds. Shipyards value installed equipment separately from the hull. Escort hiring uses the original 10% port hull price and wages use 1% of base hull cost per day; existing hired saves adopt that wage without rebilling past days. Refueling costs one credit per unit, supports partial fills, and is free at dominated ports. Operational integrity recovery repairs armor before shields without the prototype post-hit delay; boosters adjust the source recharge interval. NPCs disable after losing one third of their armor once shields are down, using the original predicate. Landing restores integrity for free. Escape-pod rescue now returns to Levo when available, advances thirty days, clears the fleet and resets legal records while retaining completed story and interaction memory. Its confirmation explains the consequences. Original title letter shortcuts work without interfering with pilot-name entry.

Mission 228's return-to-origin behavior is confirmed from the original port resolver. Mission 224's anomalous pickup value remains intentionally repaired. See [evidence and remaining verification](research/reports/ORIGINAL_FIDELITY_0_1_45.md); full manual original-game comparisons and exact AI/timing parity are still open. Add-ons are excluded.

## Original cargo-scan rules — version 0.1.46

Mission cargo scans now require the exact source government, eligible patrol AI, active smuggling enforcement, and the original 180-unit range on each axis. Friendly escorts and departing contacts cannot accidentally enforce another faction's cargo restrictions. Detection uses the real SmugPenalty field, so penalties and scan-abort missions no longer reach a missing-field error. Scan timing retains fractional time and resets for fresh encounters. Exact original AI acquisition timing remains under comparison; see [source evidence and checks](research/reports/ORIGINAL_SCANS_0_1_46.md).

## Auxiliary encounter arrivals — version 0.1.47

Auxiliary mission ships now use the original separate randomized arrival counter. New encounters reset the delay, repeated updates cannot duplicate waves, and destroyed finite reinforcements stay destroyed after reload. Exact original real-time cadence remains unverified; the remake uses a nominal 60 updates per second. See [arrival evidence and limits](research/reports/ORIGINAL_AUXILIARY_ARRIVALS_0_1_47.md).

## Wreck blast recoil — version 0.1.48

Each delayed wreck explosion now kicks every still-burning piece away from the blast, reversing inward motion and preserving position at impact. Hulls of 300 tons or more—including cruisers—randomly split into two or three actual clipped hull sections. Each section has sealed glowing cut faces, its own staggered detonation and independent crew audio. Smaller ships retain two-piece breakups. Impulses resolve chronologically and produce the same trajectories at 30, 60 and 120 FPS.

Verified with 52 breakup checks, 31 explosion checks, 115 game regressions and rendered three-piece cruiser captures.

## Wreck crew variety — version 0.1.49

Four new phrases, with two generated performances each, join the wreck crew pool: George's solemn British “I go to my fathers,” Callum's frantic “Why did I fire on them?”, Callum's evacuation order “The engines are gone! Everybody out!”, and Harry's weary “Tell my family I tried.” Human wreck sections draw from a shared shuffled six-phrase rotation with no immediate repeat; a three-piece wreck always gets three different phrases. Each six-second mix now contains one foreground line rather than adding “This is the end” into other mixes. Alien wreck recordings and pause/mute/individual detonation behavior are preserved.

The original MP3s, voice names and direction tags are retained in `research/audio/elevenlabs/manifest.json`. Reimport on macOS with `python3 tools/generate_panic_audio.py --prefix wreck_line_`, then `python3 tools/mix_wreck_audio.py`. Verified with 55 breakup/rotation checks and 110 panic-audio regressions.

## Rocky asteroid models — version 0.1.50

Asteroid fields now use twelve irregular rock meshes with excavated crater bowls, weathered rims, fine stone grain and muted gray/brown mineral variation. Fully rough, nonmetallic surfaces replace the smooth shiny ellipsoids. Meshes and materials are shared across the field; system placement, density and projectile obstruction behavior are preserved. The variants are previewed in `builds/asteroids-0.1.50.png`.

## Compact bottom-screen appeals — version 0.1.51

Death Star appeals now use the existing bottom flight-message line with compact Accept, Deny and Spare them buttons directly beneath it. The large bordered panel and duplicate message are removed. The bottom layout grows for wrapped text and buttons while staying above the screen edge. Flight remains live during requests. Verified with all 20 live-appeal checks and a rendered layout capture in `builds/live-appeal-0.1.51.png`.

## Smooth window transitions — version 0.1.52

Gameplay windows open with a 180 ms eased fade and a subtle scale from 98.5% to full size, centered on the viewport. Closing windows fade and shrink over 120 ms with input disabled immediately. Content refreshes within the same screen do not replay the transition; rapid switching cancels stale motion and cleans up closing views. The title menu retains its existing animation. Focused checks cover settled transforms, refreshes, closing input and rapid switches.

## Stable Death Star surface — version 0.1.53

The station's procedural armor seams, tiny lights and equatorial trench now use screen-space filtering. Subpixel details fade instead of aliasing into rippling bands, longitude wraps cleanly, and a filtered planar armor cap replaces converging polar lines. The dish and weapon sequence are unchanged. Rendered at three sizes and orientations in `builds/death-star-surface-0.1.53.png`; 113 Death Star and 62 bribe checks pass.

## Explosion variety — version 0.1.54

Ship and wreck-section detonations now randomly choose among four visual styles: the classic thermal fireball; a blue-white reactor rupture with irregular jets and three expanding rings; an ammunition chain reaction with staggered secondary flashes, smaller shockwaves and more sparks; and a larger, slower red-orange fuel bloom with lingering smoke. Colors, timing, shape and debris glow vary together. Existing pause, crew, drift and cleanup behavior is preserved. Variant captures are in `builds/explosion-variants-0.1.54-0.45.png` and `builds/explosion-variants-0.1.54-1.25.png`.

## The Reckoning — version 0.1.55

The station countdown now reads “The Reckoning of [target name]” for both planets and space stations, retaining the target's name while withdrawing. The red top status banner is removed. Bottom-left appeals show a live countdown and progress from neutral through gold and orange to red, with a brief highlight for new requests and a smooth urgency pulse. Responses use the shared classic gray button styling and Geneva-family font. Verified with 27 live-appeal, 113 Death Star and 38 classic-service checks, plus a rendered preview in `builds/reckoning-appeals-0.1.55.png`.

## Forklift tear-through — version 0.1.56

When a forklift's direct hit destroys a ship with a delayed hull breakup, the forklift keeps its model, speed, direction and remaining lifetime, passing through the split wreck instead of disappearing in an impact blast. It stops homing on the destroyed target. Immediate explosions, nonlethal hits and other weapons retain their existing impact behavior. Focused checks cover surviving motion, disabled homing, lifetime cleanup and the unaffected impact cases; breakup, special-effects and game regressions also pass.

## Demand a larger bribe — version 0.1.57

Live reckoning offers include an “Ask for more” button. Authorities randomly agree with a larger, variable bribe or refuse. Each refusal permanently increases that deployment's countdown rate by 0.5×, capped at 3×; the active rate is displayed beside the bottom timer. The previous offer can still be accepted. Requests have an eight-countdown-second cooldown, remain nonmodal, are recorded in contact history, and retain their rate and negotiation state across saves. Pause still freezes the accelerated timer. Older saves default to normal speed.

## Bombardment during the reckoning — version 0.1.58

Player projectiles and damaging beams can strike the threatened planet or station during its active reckoning. Hits stop at the near surface with impact sparks, immediately replace haughty responses with frightened apologies, and trigger a larger offer. Sustained fire escalates the pleas further; offers increase at most once per six countdown seconds. Fear persists for the deployment and survives reloads, and bombardment is recorded in contact history. Intervening ships and asteroids block shots; NPC fire, flares and tractor beams do not trigger intimidation. Ordinary weapons leave the target intact for the reckoning's final destruction.

## Moving asteroids and shattered remnants — version 0.1.59

Asteroids now drift independently and tumble in three dimensions, following a direct original-game visual comparison. Their cover positions move with their models, menus freeze their motion, and distant rocks recycle around a travelling pilot. Shattered planets leave charred irregular rocks with cooling fissures; destroyed stations leave torn metal plates and spars with heated cut edges. Remnants keep flying outward. See [original observations, screenshots and timing limits](research/reports/ASTEROIDS_AND_REMNANTS_0_1_59.md).

## Original-inspired ordnance — version 0.1.60

Space bombs, heavy rockets, missiles, torpedoes and decoy flares now have distinct in-flight visuals based on their original EV 1.0.5 sprites. Silver bombs have pointed casings and tail fins; heavy rockets have long silver bodies, green fins and blue exhaust; missiles use red trim and blue exhaust; torpedoes glow yellow with tapered tails; decoy flares pulse as red crosses. These replace the generic projectile boxes while preserving guidance, damage, speed, lifetime, sounds and countermeasure behavior.

Original references are spïn 203/204/206/207/209 and PICT 204/206/212/214/218, resolved from each weapon's Graphic field. `python3 tools/extract_projectile_reference.py` recreates the extracted reference frames and labeled atlas in `research/decoded/projectile-reference`. The updated models are previewed in `builds/projectile-models-0.1.60.png`.


## Fresh GitHub checkout

The runtime catalog and game assets are included. Install Godot 4.7.2, import
`godot/project.godot`, and run the project. The local `.tools/` engine and `builds/`
exports are excluded from Git. You can also run `godot --path godot` with Godot on
your PATH. Regenerating original resource data is optional and requires the local
resource dump described above. Update the machine-specific export template paths
in `godot/export_presets.cfg` before exporting on another computer.


## 0.1.61 — Javelin rocket artwork

Javelin rockets now use a compact silver body, blunt tapered nose, bright motor
collar and narrow blue exhaust, based on the original spïn 208 / PICT 216 frame.
The new model replaces the generic box for player and NPC shots; damage, firing
rate, flight speed and lifetime are unchanged.


## 0.1.62 — Fighters follow hyperspace

Launched bay fighters now survive normal and chain jumps. They warp in behind
the flagship after a short staggered delay, using the ship arrival stretch and
settling animation, then resume escort combat. Arrival delays advance only with
flight simulation. Fresh pilot/system loads still clear transient bay fighters.
