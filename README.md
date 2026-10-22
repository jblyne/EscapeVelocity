# Escape Velocity HD — First Flight

A playable Godot 4 reconstruction built around the original Escape Velocity 1.0.5 resource data, with modern 3D presentation and requested custom features. Full manual original-game parity remains under acceptance review.

## Download and install (no Godot needed)

Download **0.1.234**, `Escape-Velocity-HD-0.1.234-macOS.zip`, from [the GitHub release](https://github.com/jblyne/EscapeVelocity/releases/tag/v0.1.234). The standalone universal app includes Apple Silicon and Intel code; execution on Intel still needs acceptance testing. Full manual campaign comparisons are pending; see [Phase 6 acceptance status](research/reports/PHASE_6_ACCEPTANCE.md).

1. Unzip the download.
2. Drag **Escape Velocity HD.app** into **Applications**.
3. Open it from Applications.

This development build is ad-hoc signed, but is not Apple Developer ID signed or notarized. macOS may block the first launch. If you trust this download, use **System Settings → Privacy & Security → Open Anyway** after attempting to open it, then confirm Open. No Godot editor or separate asset download is required. Pilot saves stay in the app's user data folder when updating the app.

Choose the macOS ZIP under **Assets**; GitHub's **Source code** archives are for development. Windows and Linux downloads are not included in this release.

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

**Chain hyperjump:** enable it in **C**, open **M**, and select any system. The map highlights the shortest route in gold and draws a direct destination line. Return to flight and press **J** once: the first hop uses the full stop, align, spool, and acceleration sequence. Subsequent hops arrive with a boom, fly through the system for one second at retained hyperspace speed, stretch rapidly in the last quarter second, and jump instantly onward. While this cheat is enabled and you exceed 1.5× cruise speed, your wake destroys other ships within 300 distance units of your swept flight path, during hyperspace acceleration and active chained flybys; captured escorts are spared. The final arrival returns to normal cruise speed. Fuel and gravity restrictions are bypassed. **J** cancels at the current stop; menus pause the countdown. Your fleet travels with you, and the toggle saves with your pilot.

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
| Left / Right (D also turns right) | Turn |
| A | Open autopilot / cancel active autopilot |
| S / Down | Face opposite drift; then use W / Up thrust to slow down |
| Space | Fire selected weapon |
| Q / E | Previous / next available weapon |
| C | Open / close cheat menu (weapons, infinite fuel, Invincibility, Deflection) |
| Tab | Cycle contacts → no selection → first contact; show selected ship preview / information |
| L | Request clearance / land / launch; double-tap for auto-land |
| 1–4 | Select a landing world (L requests its clearance) |
| M | Open / close galaxy chart |
| N | Cycle connected jump destinations |
| J | Stop, align, spool, accelerate into hyperspace / cancel |
| Y | Hail selected ship / close communications |
| B | Board selected disabled ship; double-tap for auto-board |
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


## 0.1.63 — Persistent remnant fields

Revisiting a destroyed planet or station restores a cold, seeded debris field at
the body's former location. Rocky fragments or torn metal plates slowly tumble
in place instead of replaying the outward blast. Fresh destruction still throws
fragments outward continuously.

## 0.1.64 — Classic startup sequence

Normal app launch now shows the original Ambrosia publisher logo (PICT 8100),
Escape Velocity launch artwork (PICT 131) with actual threaded scene-loading
progress, then the original STR# 20000 story over PICT 8200 before the main menu.
Click, Space or Escape advances the logo or skips the story. The full story
scrolls automatically; modern display durations, scroll rate and text shading
are reconstructed rather than verified frame-for-frame original timing.
The game menu and pilot save behavior remain unchanged. `--skip-intro` and the
existing direct-screen debug arguments bypass the introduction.


## 0.1.65 — Detailed drifting wreckage

Persistent station fields mix broken pressure modules, structural ring sections,
torn equipment panels and hull plates, scattered through the field instead of
forming an empty ring. Planet and station remnants tumble more visibly and
follow gentle, seeded local drift paths that remain bounded around their
original positions. The initial blast still sends loose fragments outward.

## 0.1.66 — Original startup music and cue order

Verified the original executable's startup calls: title music (snd 30000) begins
with the publisher logo and continues through loading and the main menu without
restarting. The story belongs to a new pilot's first ship entry, rather than
before the menu; loaded pilots skip it. The Levo image plays Transition (30003)
and holds up to eight seconds, followed by the black story scroll with Drum
Intro (30001) handing off to Drum Loop (30002). All music preserves original PCM.
The story's normal source scroll rate is 30 pixels/second at 640×480. Loading
length remains dependent on hardware. See
[the source cue audit](research/reports/ORIGINAL_STARTUP_0_1_66.md).

## 0.1.67 — Original interface and boarding sounds

Restored all five original interface beeps and the Airlock recording. Ship/world
and navigation targeting, service-list selection, landing clearance/completion,
refusals, equipment transactions, mission acceptance and boarding now have
original sound feedback. Landing no longer plays its generated two-tone chime.
Generic modal buttons also use the original Click recording. Audio remains
mutable and selection sounds do not repeat during UI refreshes. Some cue
placements adapt original sounds to the remake's interactions; see
[the interface audio notes](research/reports/ORIGINAL_INTERFACE_AUDIO_0_1_67.md).


## 0.1.68 — Mission comparison indicators

Mission offers now show shortest connected jump counts beside each title and
a gold star for the closest offers. Sort: nearest toggles distance ordering while
retaining the selected mission; Sort: original restores source order. The detail
pane summarizes the next objective, cargo requirement, reward and days remaining,
with a warning when cargo space is insufficient. Courier jobs participate too.
Distances are to the next known objective, not a promise of total mission travel;
return legs and later stages can add jumps. Unknown/disconnected goals are marked
explicitly and never use the chain-jump cheat's isolated-system fallback.


## 0.1.69 — Classic ship communications

Ship hailing now uses a compact black dialog with a thin square border, captain
response at upper left, ship portrait and identity at right, and grey beveled
communication buttons below. Assistance, bribes and offered contracts use the
same presentation, with scrolling for long responses. Existing actions and
keyboard shortcuts remain; boarding remains accessible via its shortcut. The
layout follows the observed original hail arrangement documented in
[the interaction reference](research/reports/ORIGINAL_SHIP_INTERACTIONS.md).


## 0.1.70 — Full-tank refuel button

The planet/station Refuel Ship button is disabled when fuel reaches tank
capacity, with a Fuel tank full tooltip. The existing post-purchase refresh
updates the button immediately after refueling.

## 0.1.71 — Menu machinery waits for presentation

Panel animation and its machinery sound now begin only after the first menu
frame has rendered. The first subsequent process delta discards scene-loading
and shader-warmup time, preventing a premature panel slam behind startup art.
Leaving the menu before its first draw cancels the pending sound. The original
title music continues uninterrupted across the startup/menu handoff.


## 0.1.72 — Classic ship-destroyed dialog

The ship-destroyed screen now follows the compact black message-dialog style,
with a thin square border, plain text and grey beveled recovery buttons. It
retains the explosion reveal delay, last-living-save protection and strict-pilot
restrictions; Load Last Save is disabled when no pilot file exists.


## 0.1.73 — Commodity prices on the map

The selected-system panel now shows current commodity exchange prices in cr/t,
using the same reputation and active-event pricing as the ports. Multiple local
markets show a minimum–maximum range; hovering the price lists each port's quote.
Unexplored systems retain hidden market information, and destroyed or non-trading
ports contribute no quotes.


## 0.1.74 — Silent thrusters

Normal thrust and afterburner flight no longer play the looping engine sound.
Thruster visuals and the other game sounds retain their existing behavior.


## 0.1.75 — Original jump-initiation sound

A valid J jump request now immediately plays original Warp Up (snd 128), with
its original PCM and pitch. It pauses with flight and stops on cancellation,
system reload, or handoff to the existing acceleration sound. Invalid requests
and the second J used to cancel do not start the recording. Original reference:
0x5b304 loads snd 128; the hyperspace charge path plays it at 0x35810–0x35828.
The remake starts it on the accepted request so the stop/align phase has audible
feedback too.


## 0.1.76 — Silent hyperspace acceleration

Removed the generated acceleration/engine sound during hyperspace as well as
normal thrust. Original Warp Up still plays when J initiates a valid jump; the
existing arrival effect is retained.

## 0.1.77 — Hyperspace hum without wind

Restored the rising tonal hum during the departure burn, removing the noise layer from its waveform. Ordinary thrusters remain silent; original jump initiation and arrival cues remain.

## 0.1.78 — Original hyperspace recordings and phase timing

J is silent during stopping and alignment. Original snd 128 Warp Up begins at spooling and continues through acceleration, without synthesized jump audio. Original snd 130 Warp Out replaces the generated arrival sound. Both play at native pitch.

## 0.1.79 — Jump confirmation and complete warp recording

Accepted J plays original Beep3 (snd 152). Spool plus departure burn now lasts the full native Warp Up recording, rather than cutting it short at a fixed burn duration.

## 0.1.80 — Mission landing arrows

Red flight arrows label the specific planet or station needed for each current landing objective, including courier deliveries and return stops. Offscreen arrows point toward the destination and stay clear of the right instrument panel. Markers follow mission progress and omit destroyed worlds.

## 0.1.81 — Double-tap auto landing

Double-tap L within 350 ms to approach the selected world (or nearest if unselected), brake using the main engine, and land after clearance, position and speed checks. L, manual steering/thrust, changing destination, menus or jumping cancel the approach. Landing refusals remain enforced.

## 0.1.82 — Original capital ship silhouettes

Rebuilt Confederate Frigate/Cruiser and Rebel Destroyer/Cruiser geometry against original PICT 1010, 1012, 1024 and 1026. Restored silver spines, swept blue Confederate aft housings, cruiser hangar asymmetry, and narrow Rebel hulls with red outriggers and squared engine bays. Ship statistics and weapons remain unchanged.

## 0.1.83 — Rush labels on mission map arrows

Timed mission arrows now show RUSH and remaining game days, highlighting deadlines due today or tomorrow. Shared destinations show the number of rush contracts and earliest deadline. Untimed and hidden-arrow missions retain their existing presentation.

## 0.1.84 — Classic pause menu

Restyled flight pause menu to the shared black, gray bordered classic interface with gray buttons. Controls use current bindings in a compact two-column reference with its own scroll area; menu actions remain visible alongside it. Added the auto-land shortcut to the reference.

## 0.1.85 — Local leads and unlock guides

Map Leads & Unlocks and landing Local Leads & Unlocks present story leads gated by campaign progress, with combat/reputation advice and intermittent-offer guidance. Lists derive local special-tech outfits and shipyard stock from original port technology and clearance requirements. Unknown systems require exploration; destroyed ports are omitted.

## 0.1.86 — Bar approaches and landing trigger audit

Entering a spaceport bar now presents eligible original mission approaches with original offer prose and accept/decline controls. Resolved offers do not repeat during the same landing visit; original chance, progression, reputation, cargo and slot limits apply. Accepted jobs show their original briefing. Physical landing refreshes the visit seed and retains completion/cargo report sequencing before newly unlocked bar follow-ups.

## 0.1.87 — Achievement badges and overall progress

Persistent per-pilot badges recognize contracts, exploration, wealth, combat rating, fleets, story milestones, experimental equipment and the reckoning. New badges display a nonblocking medal toast and remain earned after spending credits or losing ships. Open Achievements from the pause menu or ship information. Overall completion is 40% systems visited and 60% seven main story tracks, counting the chosen military and special-operations branch; opposite-faction paths and repeat jobs are not required. Existing pilots recover milestones from recorded history; older saves remain compatible.

## 0.1.88 — Gray unavailable outfitter items

Outfitter items unavailable at the current port now have dim grayscale icons and gray names, including their selected preview. They remain selectable for descriptions and selling owned units. Affordability and free-space limits do not gray items that the port actually stocks.

## 0.1.89 — Original bar encounter ordering

Bar entry prepares encounters; approaches now appear through the bar idle loop after the bar is visible, rather than immediately inside the entry button. Restored the original idle-counter ranges and stable same-port chance rolls. Re-entering or landing at the same bar no longer rerolls its encounters; visiting another bar refreshes the rolls. Mission prerequisites are rechecked before presentation. Null events are represented at nominal 60 Hz, rather than claiming identical vintage Macintosh wall-clock cadence.

## 0.1.90 — Mission and commodity autopilot

Autopilot / F6 opens active transport missions or known adjacent-system low/high commodity loops. Choosing a row engages normal flight, gravity-well departure, connected jumps, landing and paid refueling. Trade loops buy cargo with a fuel reserve, sell only the units acquired for the loop, and return to repeat; live price/access changes stop the route. Story reports wait for Okay, and combat/boarding objectives require manual completion. The button or F6 cancels immediately; steering or manual navigation also cancels. Automation is deliberately transient and does not resume after loading a pilot.

## 0.1.91 — Consistent classic dialogs

Converted the remaining shared blue rounded dialogs to black panels, thin gray borders, Geneva-style text and the same beveled gray buttons as the classic port screens. This includes ship information, target inspection, cheats and confirmation dialogs. Ship information actions use a compact two-column layout. Existing dialog animations and actions are preserved.

## 0.1.92 — Autopilot interruption and shortcut

Autopilot now uses A, with left steering on the Left arrow. Existing saved A bindings are migrated while preserving other customized controls. Manual flight input cancels automation before it can start another jump or chain hop, and cancellation clears the automated map route so the picker can be reopened.

## 0.1.93 — Flight reputation readout

A compact classic HUD below Autopilot displays live combat rating, progress between combat achievement milestones, and signed government standing with centered reputation gauges. Confederation and Rebellion are always visible; other local governments or independent local legal records appear when applicable. Red indicates negative or hostile standing, green positive standing, gray neutral.

## 0.1.94 — Compact reputation instruments

Replaced the floating reputation box with a thin three-cell instrument row between navigation and weapons in the classic sidebar. Crossed blades show combat progress, a blue shield Confederation standing, and a red winged star Rebellion standing. Hover for exact names and scores; signed reputation gauges extend left or right of neutral.

## 0.1.95 — Existing cargo in trade autopilot

Trade autopilot recognizes the chosen commodity already carried by the flagship or fleet and sells it at the low-price stop first, then starts the normal buy-low/sell-high loop. Route selection previews the existing quantity and first sale destination. Unrelated goods remain aboard.

## 0.1.96 — Sell existing trade cargo high first

Following the clarified route behavior, autopilot takes existing cargo of the selected commodity directly to the high-price stop for sale, then returns to buy low and repeats the normal loop. The route picker previews that first sale destination. This supersedes the low-price initial sale in 0.1.95.

## 0.1.97 — Autopilot activity indicator

Replaced the persistent Autopilot button with an active-only classic readout showing the mission or commodity route, both trading stops, and the current flight step. Manual interruption hides it. A remains the shortcut to open or cancel autopilot.

## 0.1.98 — Unframed autopilot readout

Removed the background and border from the active autopilot indicator, leaving its text directly over space.

## 0.1.99 — Matching ratings panel bevel

The ratings row now uses the same shared recessed background and raised gray bevel as the navigation, weapons, and other sidebar panels.

## 0.1.100 — Simpler autopilot overlay

Removed the current-step row from the autopilot overlay; only the active status and selected route or mission remain.

## 0.1.101 — SS-Maverick Tomcat

Added a space-rated F-14-inspired Tomcat with swept wings, tandem cockpit, twin engine nacelles and twin fins. SS-Maverick appears as an occasional neutral radio contact (checks every 3–7 minutes of flight; one at a time) and leaves after its flyby. Radio chatter mixes two short film quotes with original space-pilot banter and avoids immediate repeats. Hailing the ship also produces its chatter.

The ship is sold at tech-level-three shipyards for a base 650,000 credits, with an M61 machine gun, Sidewinder rail and eight guided AIM-9 missiles. All three outfits are stocked at tech-three outfitters. Hull, loadout and ammunition persist through saves.

Player kills while flying the Tomcat trigger an original synthesized victory sting, with an eight-second cooldown. No Top Gun soundtrack recording is included. A user-supplied licensed Ogg Vorbis file named `maverick_victory.ogg` in the game's user data directory replaces the sting (restart required). `tools/generate_maverick_audio.py` reproducibly generates the original gun and victory effects.

## 0.1.102 — Supplied Maverick music

Bundled the user-supplied Maverick Music.mp3 as the Tomcat kill cue, replacing the synthesized placeholder. The complete roughly nine-second clip plays once; further kills do not restart it while it is playing. Pause and mute behavior and the optional user-data Ogg override are retained.

## 0.1.103 — Open Pilot file selection

Open Pilot now presents a filesystem chooser for saved pilot JSON files, starting in the active save directory. Selecting a valid pilot updates the title readout and enables Enter Ship; subsequent saves use the selected file. Invalid, unreadable or permanently deceased pilots show recoverable errors without replacing the current pilot. Opening a pilot clears transient encounters and pending reports from the previous pilot.

## 0.1.104 — Separate pilot files

Creating a pilot saves the current pilot first, then writes a separate uniquely named JSON file in the same save folder. Duplicate names receive a numeric suffix. A failed save or file creation keeps the current pilot active. Switching to a different pilot file also saves the previous living pilot; F9 still reloads without saving over the restore point. Normal dead pilots retain their last living save.

The selected pilot file is remembered for the next app launch; explicit --save-path overrides remain isolated.

## 0.1.105 — Triple forklift damage

Tripled the forklift weapon’s mass and energy damage from 1,000 to 3,000 each. Its firing rate, blast radius and split-hull pass-through behavior are unchanged.

## 0.1.106 — Tomcat wing silhouette

Reshaped SS-Maverick with fixed wing gloves, separate moderately swept outer wing panels, clipped tips, pivot covers and flap seams. Broader distinct tailplanes leave a visible gap behind the main wings, replacing the previous delta-like silhouette.

## 0.1.107 — Animated Tomcat wing sweep

SS-Maverick now has independently pivoted wings that smoothly sweep back over two seconds when preparing for hyperspace. They reopen smoothly after cancellation or arrival. NPC departures use the same wing animation, while static shipyard previews remain open.

## 0.1.108 — Sidewinder launch acceleration

Sidewinders deploy at 230 units/second for 0.15 seconds, then smoothly boost to their normal 1,050-unit cruise speed by 0.7 seconds. Boost works with or without a guidance target; other missiles retain their existing launch behavior.

## 0.1.109 — Alternating Sidewinder wing launches

Sidewinders launch from visible wing pylons, alternating left, right, left per ship. Pylons follow the Tomcat’s animated wing sweep. Player and NPC launch sequences are independent, and launch positions use physics coordinates to avoid interpolation drift.

## 0.1.110 — Supplied Maverick target and missile audio

SS-Maverick uses the supplied target beep for Tab contact changes. Its Sidewinder and standard missile launches play the supplied missile clip in addition to the normal weapon sound, including distance attenuation for NPC Mavericks. Other ships keep their normal sounds. Both new effects honor mute and pause.

## 0.1.111 — Revised Maverick missile firing cue

Replaced the additional Maverick missile firing clip with the supplied missle lock 2.mp3. The original supplied Tab targeting beep remains in use.

## 0.1.112 — Sidewinder smoke and speed

Reduced Sidewinder cruise speed from 1,050 to 900 while keeping the slow launch and boost ramp. Boosted missiles leave soft gray smoke that expands, drifts slightly and fades over 1.6 seconds, persisting briefly after impact. Smoke uses a capped instanced batch and respects pause.

## 0.1.113 — Dedicated Sidewinder launch sound

Sidewinders now use the supplied Missle Fire Sound.mp3 instead of the normal missile launch sample. The additional Maverick firing cue remains layered on top; standard missiles retain their original sound.

## 0.1.114 — Maverick warp music

The supplied Danger Zone Warp Music.mp3 starts with the player Tomcat’s jump preparation. It plays continuously across chained system transitions, looping if needed, then fades out over three real-time seconds after the final arrival or a canceled jump. Menus pause playback and fading; mute is respected. Other hulls retain their normal warp audio.

## 0.1.115 — Louder Maverick warp music

Raised the Maverick warp music by 8 dB, retaining the three-second fade and continuous playback through chained warps.

## 0.1.116 — Louder Maverick victory music

Raised the Maverick ship-destruction victory music by 8 dB.

## 0.1.117 — Doubled Maverick music levels

Increased both warp and victory music by another 6.02 dB (double playback amplitude).

## 0.1.118 — Supplied M61 firing loop

The M61 uses the supplied Machine Gun Fire.mp3. Sustained fire repeats one audio voice without restarting the clip on every bullet; playback stops shortly after the last shot or when flight is paused.

## 0.1.119 — Sidewinder damage balance

Sidewinder mass and energy damage are now half the buffed forklift’s values (1,500 each), producing exactly half its effective direct shield and armor damage.

## 0.1.120 — Louder warp song

Raised the Maverick warp song by another 6 dB, preserving its chained-jump playback and fade.

## 0.1.121 — Triple Maverick cargo space

Increased SS-Maverick cargo capacity from 12 to 36 tons. Existing saves use the updated hull capacity when loaded.

## 0.1.122 — Random Maverick victory music

Maverick kills randomly choose between the original supplied victory clip and Great Balls of Fire.mp3 at the same playback level. Music already playing is not interrupted or restarted. Great Balls of Fire fades to silence over its final two seconds; the first track keeps its existing ending. The optional user-data Ogg override replaces the first choice.

## 0.1.123 — Maverick high-output afterburner

SS-Maverick includes an afterburner. It raises maximum speed to 2.5× normal and acceleration to 2.75×, compared with the standard 1.8× speed / 2× acceleration, using the normal fuel drain. Its active afterburner produces orange flames with a hot yellow core; ordinary thrust remains blue. Existing Maverick saves receive the stock afterburner once, without re-granting one that was deliberately sold afterward.

## 0.1.124 — Orange Maverick hyperspace exhaust

Maverick hyperspace acceleration uses the same intense orange/yellow exhaust as its afterburner, including chained flybys and NPC departures. Other ships keep their existing exhaust colors.

## 0.1.125 — Subtle afterburner thrust audio

Added a quiet, original low tonal rumble while an installed afterburner is actively used. The seamless loop fades in over 0.12 seconds and out over 0.22 seconds, stops for pause/mute, and is not used for normal thrust or hyperspace.

## 0.1.126 — Supplied Maverick afterburner audio

Maverick afterburner playback now uses the supplied Afterburner Sound.mp3 on loop, with the existing short fade-in and release fade-out. Other ships retain their current afterburner sound.

## 0.1.127 — Revised, louder Maverick afterburner

Replaced Maverick afterburner playback with the supplied Afterbuner 2.mp3 and raised its level by 6 dB, preserving looping and release fading.

## 0.1.128 — Louder Maverick afterburner

Raised the Maverick afterburner by 3 dB while retaining looping and smooth release fading.

## 0.1.129 — Dedicated AIM-9 Sidewinder model

Replaced the shared red missile mesh with a slim light-gray Sidewinder body, dark rounded seeker, four forward control fins, four larger tail fins, tail roller details, identification bands and a narrow rocket plume. Outfitter ammunition previews use the same model. Reference: USAF AIM-9 Sidewinder fact sheet and museum exhibit.

## 0.1.130 — Afterburner wing sweep

Maverick wings now sweep back over two seconds during active afterburner use and smoothly reopen on release, using the same animation as hyperspace. Speed, sound and wing animation share the actual afterburner activation check, including equipment and fuel requirements.

## 0.1.131 — Reliable projectile hit selection

- Projectiles now hit the nearest ship surface along their flight segment, rather than the first overlapping contact in the traffic list.
- Sidewinder regression checks cover bulk freighter destruction, surviving target integrity updates, shield-only damage, and near misses.

## 0.1.132 — Readable firework pleas

Threatened worlds reserve separate firework message positions above and below their surface. A second active plea uses the bottom position; additional simultaneous launches are skipped instead of overlapping existing text. Expired messages release their position.

## 0.1.133 — Widescreen and ultrawide play

The game viewport now expands to fill the window's aspect ratio, including 21:9 and 32:9 displays, instead of retaining the original 16:10 frame. Wider displays reveal more space horizontally while preserving ship proportions, vertical camera scale, and the right-aligned HUD. Press **F11** in game to toggle fullscreen. Original startup and main-menu artwork keeps its original proportions.

## 0.1.134 — Keep outfitter scroll position

Buying or selling equipment now restores the scroll position after the rebuilt grid finishes layout. The selected item stays selected, so repeated purchases no longer require scrolling back to the bottom.

## 0.1.135 — Ammunition on the flight HUD

The selected weapon display now includes its remaining ammunition in parentheses, updates immediately when firing or buying ammunition, and shows zero when empty. Unlimited weapons retain their names without a finite count; the infinite-ammunition cheat shows ∞ for ammunition-based weapons. Long weapon names shrink to keep the count visible.

Maverick cargo capacity is now **72 tonnes** (doubled from 36). New purchases include **Tritanium Armor** and an **IFF Decoder** alongside the existing loadout. Existing Maverick pilot saves receive those two outfits once on loading; deliberately selling them afterward does not re-grant them.

## 0.1.136 — Double Maverick fuel capacity

SS-Maverick now has an 800-unit fuel tank, doubled from 400, allowing eight standard jumps before refueling. Existing Maverick pilots receive the larger capacity while keeping their current fuel; new purchases start with a full tank.

## 0.1.137 — Maverick Sidewinder resupply everywhere

Every port with an outfitter stocks AIM-9 Sidewinder ammunition for pilots currently flying SS-Maverick, regardless of local technology level. Other ships cannot purchase Sidewinders. Normal credit, equipment-space and launcher requirements still apply.

## 0.1.138 — Triple Maverick shields

SS-Maverick's base shield capacity is now 780, tripled from 260. New purchases start with full shields. Existing Maverick pilots receive the higher capacity while retaining their current shield charge, which can recharge normally.

## 0.1.139 — Landing bribes and optional Death Star

When a planet or station refuses landing because of your reputation, hail it with **H** and choose **Bribe for landing clearance**. The displayed price is 5,000 credits plus 1,000 per technology level. Payment grants clearance for the current system visit without changing reputation, and is recorded in interaction history. Destroyed worlds, missing facilities and active defense battles cannot be bribed into allowing landing.

The **Death Star · world-killer** toggle in the cheat menu now controls access to threats and deployment. It defaults off and saves with the pilot. Existing countdowns can still be resolved when the toggle is off.

## 0.1.140 — Longer-range Sidewinders

Tripled AIM-9 Sidewinder flight time from about 2.92 to 8.75 seconds for three times the nominal range. Launch acceleration, cruise speed, guidance, damage, and smoke trails are unchanged.

## 0.1.141 — Double Maverick outfitting space

SS-Maverick now has 56 tonnes of free outfitting space beyond its stock loadout, doubled from 28. The higher capacity applies to new purchases and existing Maverick pilot saves.

## 0.1.142 — Mission destination landing access

Active courier, passenger, cargo and other ready-to-land mission objectives grant landing access at their exact next planet or station even with insufficient faction standing. Clearance follows a mission's delivery and return stops, ends when the mission is removed or expires, and does not change reputation. Destroyed worlds, missing facilities and active defense battles still block landing. Eligible mission landings do not require a bribe.

## 0.1.143 — Rebel Fake ID Papers

Privateer's Haven in NGC-1896 now sells Rebel Fake ID Papers alongside the original Confederation papers, using the same special-stock rules and 2,500,000-credit base price (normal local pricing applies). Purchasing consumes the papers and resets only a negative Rebellion record to neutral. Positive standing is preserved, and the item cannot be bought without a negative record. Later offenses can be cleared with another purchase.

## 0.1.144 — Reliable bar recruitment at neutral standing

Fixed a progression dead end: introductory Rebel Parcels and Confed Documents required positive standing even though their follow-up missions were locked behind completing those introductions. These two recruitment jobs now accept neutral standing and bypass their random appearance roll once otherwise eligible. They appear in Bar Offers and can trigger the normal bar approach. Negative standing, combat-rating requirements and allegiance/story restrictions remain enforced. Other bar missions keep their original chance and prerequisites. Empty bar offer lists now explain how recruitment and later unlocks work.

## 0.1.145 — Sidewinders defeat Cap'n Hector

A direct AIM-9 Sidewinder hit now instantly destroys Cap'n Hector, bypassing his special protection and clearing his reminder banner. Other weapons retain their existing behavior against him.

## 0.1.146 — Rival-faction combat goodwill

Destroying a Confederation ship grants +25 Rebellion standing; destroying a Rebel ship grants +25 Confederation standing. Player and player-fleet kills count, including faction patrol/escort variants. The attacked faction's existing penalties remain. Partial damage, unrelated factions and hyperspace-wake destruction do not grant this bonus; reputation is capped at 10,000.

## 0.1.147 — Ship-scaled combat goodwill

Rival-faction goodwill now scales with the destroyed hull's mass: one point per ten tonnes, rounded up. A Confed patrol ship earns 2 Rebel goodwill, a frigate 35, and a cruiser 100; a Rebel destroyer earns 24 Confederation goodwill and a cruiser 85. Escape pods earn none. Existing crime penalties and player/fleet kill-credit rules remain unchanged.

## 0.1.148 — Clear assassination objective completion

Assassination targets are labeled [MISSION TARGET]. Once all required targets are destroyed, a confirmation sound and persistent gold flight-HUD message name the exact return planet/station and system, explicitly stating that no more targets are required. The mission journal marks the job RETURN FOR PAYMENT and shows the return instruction above its briefing. The reminder clears when the mission completes.


## 0.1.149 — Limit lethal wake to actual hyperspace travel

Chain-jump wake damage now requires active hyperspace acceleration or an ongoing chained flyby, in addition to the existing speed threshold. Ordinary thrust, Maverick afterburner use and fast coasting no longer destroy nearby ships just because the chain-jump cheat is enabled. Rebel Defense's five required attackers now receive mission-target labels and a persistent return-for-payment message once eliminated or driven off.

## 0.1.150 — Visible local bar offers and fresh reports

Bar Offers now lists every mission whose port, standing and story prerequisites are met, independent of its random spontaneous-approach roll. Selecting a listed job uses the same eligibility rules, while automatic bar approaches retain their encounter chance. Opening a new offer list or beginning another landing visit clears old mission-report text, preventing a previous system's completion report from masking the local offer screen. The heading distinguishes eligible bar jobs from the mission computer.

## 0.1.151 — Explicit mission cloak installation

The Special Ops Insertion bar approach now distinguishes an already-installed cloak from pending installation. Its acceptance button reads Accept & install cloak when needed, and the acceptance report confirms the equipment is installed and gives the K shortcut. End-to-end checks cover the actual approach button, inventory, active mission, activation after launch and save restoration.

## 0.1.152 — Cloak offer layout and explicit scan failure

Widened the Special Ops acceptance button so its full label stays within the panel. The insertion offer now warns that a Confederation cargo scan fails the mission and reclaims its loaned cloak, making the offer eligible again. A scan-triggered failure produces a 25-second flight HUD notice and explanatory mission-report text, including cloak removal and retry instructions. Installation, persistence, scan failure, equipment removal and retry eligibility are checked end to end.

## 0.1.153 — Current mission objective on the flight screen

A persistent gold NEXT readout now names the tracked mission and its immediate action, exact destination and system. It updates for cargo/passenger pickup and delivery, combat target counts, disabling/boarding, escort rendezvous, and returning for payment. Special Ops insertion includes its K-to-cloak warning. Newly accepted jobs are tracked automatically; press I and select another journal entry to track that job. The journal also places the current next action above its original briefing, and the flight readout hides when no jobs remain.


## 0.1.154 — Original combat controls and flight utilities

Space fires every installed primary gun together, with independent reload timers and a projectile per gun mount. Q/E selects secondary weapons; Control fires the selected secondary; R toggles secondary safety. Shift remains afterburner in the remake defaults. The Classic preset uses Shift for secondary fire, W / Option+W for secondary selection, S for safety, and 2 for afterburner. All new flight actions are remappable in Settings. The weapon display shows selected secondary ammunition and SAFE status.

Backspace or **Fleet → Recall fighters to bays** brings launched fighters home, returning each surviving purchased craft to bay inventory once. Relaunch services its shields, armor, and ammunition. Fighters retain damage, ammunition, recall orders, and sortie age through hyperspace; incoming projectiles can destroy them. They automatically recall when their sortie ammunition is exhausted, badly damaged, or after a reconstructed three-minute sortie. Landing recovers surviving fighters; pilot saves include deployed purchased fighters as docked inventory so reopening a pilot does not lose them. A full flight wing rejects additional launches without deleting old fighters or spending ammunition.

Command+K (Control+K on other keyboards) dumps cargo; Option/Alt retains mission cargo. Dumping mission cargo fails the affected deliveries and explains why. Hold Command+D / Control+D for ten real seconds to self-destruct; releasing or opening a menu cancels it. Time acceleration does not shorten that hold.

Landing officials can refuse bribes or negotiate one smaller fee. The same port/day keeps the same official, preventing repeated hails from rerolling willingness; another day can bring a different official. Refusal charges nothing. These behaviors follow the original manual, while prices, willingness probabilities, and sortie duration remain reconstructed rather than verified original formulas.

Validation: `test_original_gameplay.gd` covers firing, safety, presets, fighter launch/recovery/loss/save/jump handling, cargo jettison, self-destruct cancellation and completion, and bribe refusal/negotiation. Existing combat, outfitter, Maverick, controls, fighter-jump, cargo-scan, and landing tests are also checked. The local Mac app is rebuilt; this version has not been published to GitHub.

The exported app's launch check also exposed a background-thread preload failure for shader/texture dependencies. Startup now loads the game scene on the main thread after drawing the logo; the existing logo/music/loading/story order is retained. The original startup test passes (16 checks), and the standalone Mac app launch no longer reports script/resource-loading failures.


## 0.1.155 — Combat AI and weapon-timing fidelity

NPC weapon volleys now use each recovered weapon's Reload period, without speeding it up according to gun count or imposing the old 0.12-second minimum. Multiple mounts fire together, consuming ammunition per projectile. Fractional cooldown time is retained across updates; leaving range does not bank a burst of overdue fire. NPC firing range follows the same projectile speed and lifetime used by actual shots instead of a universal 950-unit cutoff. The laser's prototype 1.5-second lifetime override is removed in favor of its recovered Count field. Custom Maverick weapon data and sounds remain in use.

Turrets require a valid designated target, as described by the original manual; rear turrets also require a target aft. NPC movement now uses the shared thrust/inertia integrator, so a turn cannot instantly redirect its existing velocity. Pursuit accounts for target motion and primary-weapon reach. These are combat-fidelity improvements, not a claim that every original AI decision or numeric engine conversion has been replicated. Patrol acquisition/scan cadence, encounter scheduling, and exact acceleration/turning conversions remain under comparison.

Regression coverage includes frame-rate-independent volleys, simultaneous mounts, ammunition exhaustion, actual projectile ranges, target requirements, rear arcs, moving-target pursuit, momentum and pause behavior, plus fleets, missions, Maverick weapons and original audio. Local Mac build: **0.1.155**; not published to GitHub.


## 0.1.156 — Clear reconnaissance debriefs and actual rewards

Reconnaissance guidance distinguishes observing contacts from destroying ships. Once observed, it says to return and report findings; missions without a cash reward no longer promise payment. Lead Rebel Patrol's original “come up empty” narrative is a successful story outcome: it awards +10 Rebellion reputation and unlocks Rescue Rebel Spy at Sirgil III's bar. Its original completion requirements and narrative remain intact.

Mission reports now visibly show completion/failure, mission name, actual credits/reputation, and an eligible bar-story handoff when one is unlocked at the return port. The original narrative remains scrollable, with outcome/status text separated above it. Checks cover the real mission 185 acceptance, reconnaissance and debrief flow, reward, unlocked follow-up, report layout, and paid-reconnaissance guidance. Local Mac build 0.1.156; not published to GitHub.


## 0.1.157 — Restore selected-weapon firing by default

The normal fire trigger (Space by default) again fires the weapon shown as selected, including Maverick Sidewinders. Q/E cycles all available weapons, so the M61 and Sidewinders remain individually selectable. The HUD no longer substitutes a secondary weapon's label while a primary gun is selected.

Separate all-primary/selected-secondary firing is now opt-in through the Classic preset or the Classic firing checkbox in Settings. This preference saves independently of key bindings and defaults off for existing preferences. Restore remake defaults returns to selected-weapon firing. Weapon range, NPC volleys, targeting rules and other recent combat fixes remain. Regression coverage exercises the actual fire-trigger dispatcher, Sidewinder ammo, M61 selection, HUD captions and preference reload. Local Mac build 0.1.157; not pushed to GitHub.


## 0.1.158 — Phase 1: mission clarity and reliability

Audited guidance across all 116 original mission records. Escort objectives keep the protection requirement visible; rescue/boarding objectives recognize ships already disabled. Flight guidance includes deadline urgency and scan risks. Offers and journals explain equipment, legal-record and military-access rewards as well as credits. Map/port leads name actual unmet faction/combat requirements.

Original non-abortable missions now show **Cannot Abort**, explain why, and warn before acceptance. Failure messages identify the cause, loaned-equipment loss and valid retry location. Failure reports cannot show success status, and failed repeat missions stop their autopilot correctly. Original campaign rewards and narrative text remain; the selected-weapon firing preference and Maverick additions are preserved.

The [Phase 1 audit](research/reports/PHASE_1_MISSION_AUDIT.md) includes the complete catalog checklist and known boundaries. Automated coverage includes every record's guidance and nine campaign routes with save/reload; complete manual campaign playthrough remains Phase 6. Local Mac build **0.1.158**; not published to GitHub.

## 0.1.159 — Phase 2: flight and combat timing

Original-executable timing replaces the provisional base-ship acceleration and turning conversions. Player cruise speed includes the original 1.75 multiplier; ordinary engine upgrades add their source values. Jump arrivals now respect effective speed and installed upgrades. Maverick handling, afterburner multipliers, wing sweep, custom weapons/audio and your default selected-weapon controls are preserved.

Shield/armor recovery follows shared original-clock pulses and signed-integrity rounding, rather than continuous smoothing. Held weapons retain fractional reload timing, and projectiles cannot travel past their lifetime on the final update. Tests compare 30/60/120/144 Hz updates. See the [Phase 2 evidence and limits](research/reports/PHASE_2_FLIGHT_COMBAT_TIMING.md) for the extracted constants, source addresses, coordinate scale and remaining differences. Local Mac build **0.1.159**, not published to GitHub.

## 0.1.160 — Dominated systems on the map

Systems containing a surviving tribute-paying world now use the original bright green map ring. Selected details show **Dominated**; hover that status to see which worlds pay tribute. The indicator follows saved conquest state and disappears when the last agreement is released or its world is destroyed. Current-location dots, mission arrows and selection brackets retain their existing roles.

## 0.1.161 — Pirate reputation in the flight sidebar

The existing reputation row now has four equal sections: combat, Confederation, Rebellion and Pirates. The new skull-and-crossbones icon uses the same signed reputation gauge, with exact pirate standing available on hover. All four sections retain the sidebar's shared bevel and background.

## 0.1.162 — Tribute retaliation

Dominated worlds hire bounty hunters that identify their employer. Defeating one raises that world's daily tribute by 5,000 credits and displays a flight alert. After five defeats, the world gives up hiring hunters, retaining its 25,000-credit daily tribute increase. The map shows current tribute, hunters sent, defeats, and give-up status, with a per-world tooltip.

Hunter contracts and tribute increases persist with the pilot. Travel and reload resume an outstanding contract without counting it twice. NPC kills do not earn a tribute increase.

## 0.1.163 — Offer assistance to disabled ships

Ship communications now includes Offer Assistance. Offer help, then approach within the displayed range and match the disabled ship's speed for three seconds. Your crew restores its engines and enough armor to resume flight; the captain remembers your assistance. Operational ships decline unnecessary repairs.

Validated with 8 rescue checks, 73 communications checks, and 35 interaction-history checks, plus native layout verification.

## 0.1.164 — Phase 3: NPC behavior and encounters

Civilian ships now evade pirates and attackers, armed merchants can defend themselves, and badly wounded ambient merchants/pirates withdraw into hyperspace. Patrols approach and match speed before inspecting illegal mission cargo. Ordinary NPC cruise speeds and original projectile launch drift now follow recovered executable rules; arriving traffic enters in motion. Mission actors, fleet ownership, tribute hunters and custom Maverick handling remain protected.

See [Phase 3 evidence and tuning limits](research/reports/PHASE_3_NPC_BEHAVIOR.md). Phase 4 covers fighter and fleet lifecycle fidelity.

## 0.1.165 — Maverick multi-target volleys and tribute celebrations

With the Maverick's Sidewinders selected in the default firing mode, hold primary fire for 0.4 seconds to lock hostile ships within missile range, limited to available rounds. Release, then press primary fire again to launch one missile per locked target simultaneously. Orange brackets and a ready prompt show the locks. A quick tap still fires one missile. Switching weapons, opening a menu, or traveling cancels locks; lost targets are skipped without spending ammunition. M61, other ships and optional classic firing retain their controls.

Bounty hunter defeats now produce a large animated announcement with sliding/fading entry, a counting tribute increase, moving sparks, employer, new daily tribute and a final give-up message.

## 0.1.166 — Phase 4: fighters and fleets

Fighters now use their full original weapon loadouts and finite ammunition. Fleet management adds fighter Defend, Attack, Formation and Hold orders alongside docking, plus shields, rounds and sortie-time status. Recall uses a physical approach and speed match; docking repairs, refuels and rearms.

Launched fighters and captured carrier wings retain damage, ammo and elapsed sortie time across travel and saves. Reload no longer services them for free, surviving NPC fighters replenish their own carrier bay, and losses cannot duplicate inventory. Existing pilots remain compatible.

See [Phase 4 evidence and tuning limits](research/reports/PHASE_4_FIGHTERS_AND_FLEETS.md). The three-minute endurance clock and approach/service timing remain documented remake tuning. Next is Phase 5: bribes and secrets.

## 0.1.167 — Boarding mission cargo clarity

Boarding mission targets are explicitly marked. Their boarding screen shows automatic mission-item recovery, explains that special cargo is separate from ordinary loot, and states the next destination. Boarding an escort instead identifies the mistake. Recorded boarding progress survives later actor synchronization, and boarding/cargo pickup save together. Astrodyne Outpost V is covered through actual boarding, saving, transport loss after recovery, and delivery to Palshife.

## 0.1.168 — Auto boarding

Double-tap **B** with a disabled ship selected to automatically approach, match speed and heading, and board. Press B again or use manual steering/thrust to cancel. Menus, jumps, and a lost or changed target also cancel the approach. Single B retains manual boarding; Shift+B retains the combat drill.

## 0.1.169 — F-14 Tomcat ship name

The purchasable ship type is now **F-14 Tomcat**. The recurring NPC pilot remains **SS-Maverick**. Existing ships retain their equipment, stats and abilities.

## 0.1.171 — F-14 EMP Disruptor

Every F-14 Tomcat now has a built-in **EMP Disruptor**, including existing pilots. Select it with Q/E and fire with Space (secondary fire in optional classic controls). A guided blue pulse disables the ship it hits without reducing its shields, hull or cargo. It recharges every two seconds, needs no ammunition or outfit space, and remains exclusive to the F-14 even with the all-weapons cheat. Invulnerable contacts resist it. Attacking and disabling still affect faction standing and mission objectives normally. Double-tap B afterward to auto board.

## 0.1.172 — Boarding target survival

Active mission ships that must be boarded are protected from incidental chain-jump wake. They receive eight seconds of protection against NPC and escort fire on arrival; afterward autonomous fire can disable them but leaves a surviving hull for boarding. This applies to the required carrier, not auxiliary escorts or assassination targets, and ends after boarding. Direct player weapons can still destroy the target and fail the mission. Existing failed attempts can be retried at their original offer location.

## 0.1.173 — Click badges for next steps

Click any incomplete achievement badge to see personalized next steps. Story badges show the active mission objective or the next contact, port and system, prerequisites, combat/reputation requirements and cargo-space needs. Guidance respects your faction path and explains intermittent offers. Exploration badges name the nearest unvisited system and jump count; other badges explain their remaining milestones and concrete actions. Back to badges preserves your scroll position. Reading guidance does not accept missions, change progress or trigger bar offers.

## 0.1.174 — Phase 5: bribes and secrets

Bribe quotes now use recovered original wallet-based formulas, government surcharges, rounding and limits. Ship hails offer negotiation; landing officials use the original willingness rule and may refuse after failed bargaining. Quotes stay fixed while considering an offer, discounts cannot stack, and payments apply once without clearing government records. Officials are isolated between pilots.

On the title screen, hold Option while choosing About for original parody credits, or Command for the original additional credits. Pilot dialogs block secret shortcuts. Satellite of Love retains its original shipyard picture and description, with no invented hull statistics.

See [Phase 5 evidence and comparison limits](research/reports/PHASE_5_BRIBES_AND_SECRETS.md). The remaining phase is full-game acceptance and release.

## 0.1.175 — Fleet screen layout

Fleet management now uses compact ship rows with separate name, command and release columns. The roster and captain offers scroll inside a bounded area; fleet orders, fighter controls, repair/rearm and Leave remain outside it. Confirmation and fighter-status blocks have their own space. The classic layout scales to smaller windows without narrow wrapped controls or clipped footer buttons.

## 0.1.176 — Fleet hyperspace formation

Hired and captured fleet ships now share the flagship’s stop, alignment, spool and hyperspace acceleration instead of continuing normal combat or Hold movement during a jump. They retain their relative positions and match the flagship’s velocity and heading, including chain-hop flybys, then arrive alongside it at the same speed with matching warp visuals. Carrier wings and deployed player fighters join the departure; existing staggered player-fighter arrivals remain. Canceling restores normal ship scale and fleet AI without deleting momentum. Health, ammunition, cargo, wages and fleet commands retain their existing persistence rules. This convoy movement implements the requested behavior; it does not claim an exact port of the original escort AI.

## 0.1.177 — Jump from badge guidance

Incomplete badge guidance now offers destination buttons linked to the actual next contact, prerequisite, active objective or exploration target. Clicking returns to flight (launching if docked), selects the shortest connected route and starts the normal J jump. Distant destinations show “Jump toward”: without chain jumping, subsequent hops remain selected for normal J input; with chain jumping enabled, the queued route runs as usual. Fuel and gravity restrictions still apply. Already-local guidance returns to flight without attempting a self-jump; alternate faction leads have separate destination buttons.

## 0.1.178 — Phase 6 acceptance candidate

Added a reproducible full-suite acceptance runner, a version/signature-checked Mac packaging tool, an explicit manual campaign checklist, and a release evidence ledger. New pilots now include the same default secret-unlock fields as restored pilots. Historical regression checks were updated for accepted flight speed, communications layout, delayed menu presentation, the F-14 name and isolated test saves. Gameplay customizations remain. See [Phase 6 results and remaining manual checks](research/reports/PHASE_6_ACCEPTANCE.md); this candidate does not claim a complete manual original-game playthrough.

Run `python3 tools/run_acceptance.py` for all Godot regressions, or repeat `--test test_name.gd` to select scripts. Logs and `results.json` are retained beneath `builds/acceptance-0.1.178`. After exporting the matching Mac app, `python3 tools/package_macos_release.py` verifies it and creates a ZIP with install notes, credits, the acceptance ledger and a separate SHA-256 checksum.

## 0.1.179 — Bounty banner spacing

Added 18 design pixels above the bounty-hunter announcement heading. The background, lower divider and particles expand by the same amount, preserving the existing spacing below the footer and between text rows.

## 0.1.180 — Steel-world reconstruction

Shattered planets, moons and stations now rebuild on the existing game-day calendar. The destruction day is debris-only; the next game day brings the first landable framework. A mostly skeletal structure is the day-20 milestone, more hull is assembled by day 40, habitats and reclaimed soil appear by day 60, and the finished steel structure with planet-side soil/water areas is complete at day 80. Geometry grows each game day rather than teleporting directly between the four artwork stages. Stations remain steel facilities.

Temporary reconstruction docks permit landing throughout rebuilding, including for pilots with hostile records. Existing local services return with those docks. Flight still enforces position and landing-speed requirements. The map shows recovery status; hover the reconstruction readout for each world's orbital portrait and progress. Landed descriptions and galactic news show the current work. Old ruined-world saves start their recovery clock when migrated because their original destruction date was not recorded. Failed missions, ended tribute agreements, historical fear and reputation consequences are retained. Shattering a rebuilt world restarts its clock without duplicating history.

All **107 bodies** have distinct seeded steel geometry and **856 rendered pictures**: four landing pictures and four orbital portraits each. Later planet pictures include reclaimed dirt and water; mature landing scenes include soil beds, reservoirs and planted rows among the steel. Generated steel/soil material maps, exact prompts and the artwork manifest are in `godot/assets/reconstruction/`. They use built-in image generation for materials and the live seeded 3D geometry for pictures. `res://tests/render_reconstruction_art.gd` reproduces the pictures; `python3 tools/audit_reconstruction_art.py` checks complete coverage and distinct image hashes.

World-state validation also now normalizes JSON numeric IDs before checking destruction/active-ultimatum membership, allowing real disk restores of recovery dates and active bribe negotiations.


## 0.1.181 — Faithful HD widescreen main menu

The main menu retains the original green outlined logo, oval star chart, six CRT panels, center pilot display, mechanical opening animation and original menu audio. Its illustration is remastered with sharper materials and edges. New outer metalwork extends into widescreen displays while the original central console and button positions keep their proportions. Pilot operations, keyboard shortcuts and hidden extras are retained.

Artwork provenance and the built-in image-generation prompt are recorded in `godot/assets/menu/art_direction.json`.


## 0.1.182 — HD publisher logo and loading artwork

The Ambrosia Software logo and Escape Velocity loading illustration now have faithful high definition remasters. The original logo stays centered and keeps its portrait proportions. The loading artwork retains the pilot, fleet, console and title, with surrounding console extensions filling widescreen monitors. Original startup fades, progress display, music handoff and story timing are retained. Built-in image-generation prompts and source references are recorded in `godot/assets/startup/art_direction.json`.


## 0.1.183 — Continuous HD menu panel animation

All six menu panels and their silver connectors now animate directly from the same HD bridge illustration at the display's frame rate. The original low resolution strips and mismatched final-art crossfade have been removed. Text fades in over the settled panels without moving them or replacing their artwork. The opening retains its original machinery sound timing and widescreen layout. Native regression checks capture all 18 opening poses and compare pixels across both the panel-stop and text-reveal boundaries.


## 0.1.184 — Restore the original menu folding motion

The HD panels now pivot and unfold in perspective using corners traced from the original PICT 8300–8312 animation poses, followed by the original lettering phase. This replaces the flat sliding reveal introduced in 0.1.183. The silver connectors deform with the folding panels; every pose uses the same HD artwork, including the settled pose, so no final image replacement occurs. Interpolation preserves the source keyframes and settles at zero velocity before the stationary text reveal. Original sound timing, live menu actions and widescreen layout are retained.


## 0.1.185 — Original menu lettering and materialization

Menu captions now use the original letterforms from PICT 8000, with the actual four noisy materialization frames from PICT 8313–8316 at their original 15 Hz timing. This replaces the generic font and opacity fade. Only the luminous ink is composited over the HD panels; the folding geometry and settled artwork remain registered. All six labels are centered in consistent text zones with balanced top/bottom spacing, including the previously crowded bottom row. The reveal illuminates each full display while keeping the final lettering aligned to its padded caption area.


## 0.1.186 — Overlapping menu ink and folding motion

The noisy lettering starts during the last folding poses instead of waiting until the plates stop. Its pixels deform with the same face geometry throughout the reveal. Corrected a registration mismatch between the traced lit bevel and the texture's dark hinge notch that previously caused the final sideways shift. The four original ink frames, resolved original letterforms, padded caption placement, menu operations and widescreen support are retained. Regression coverage verifies overlap, surface attachment and consistent hinge registration at the final keyframe.


## 0.1.187 — Startup pacing and original loading meter

Removed added startup input prompts and the loading caption. The publisher logo now remains visible for two seconds, followed by a quick incremental loading meter over approximately 1.5 seconds and a short full-bar hold. Startup screens advance automatically; Space does not bypass the publisher hold. Setup stalls cannot consume their visible display time. The meter uses the recovered original 200×10 rectangle at (316, 579) on the 832×624 canvas and original CLUT 1000 colors rather than a broad modern progress bar. It never reports completion before the game scene is available.


## 0.1.188 — Original pilot readout font

The main menu's center pilot readout now uses Geneva, matching the original game's TextFont(3) and TextSize(9) calls at 0x4d024–0x4d034. Nine points scales to twelve on the HD design canvas. The Mac app uses the system-supplied Geneva family without redistributing Apple's font file.


## 0.1.189 — Smoother original menu lettering

The settled menu labels preserve the original letterforms but now retain their original antialiased edge coverage and reconstruct it with a bicubic filter. This replaces the hard color cutoff that fragmented thin strokes and made enlarged text appear choppy. The original noisy phase-in, spacing, folding and pilot readout font remain intact.


## 0.1.190 — Temporary opening-sequence replay

About EV includes a temporary **Replay opening sequence** button for reviewing the Ambrosia logo, loading-screen meter and main-menu folding/text animation without relaunching. Replay uses the real startup timings and artwork, shares the existing title-music player and returns to a freshly animated menu. It preserves the active pilot, credits, pilot file and introduction-seen state, and respects mute.


## 0.1.191 — Startup fades through black

The loading artwork and completed meter fade fully to black, hold briefly, then the main menu fades in. The publisher-to-loading transition uses the same fade-through-black treatment. Transitions use the original 16/60-second fade interval with a short black hold, preserve continuous title music, and run identically through About EV's replay button.


## 0.1.192 — Classic Mac main-menu dialogs

Main-menu dialogs use the original Mac visual treatment: pale panels with square double borders, black text, inset black name fields, monochrome checkboxes and rounded outlined action buttons with default-button rings. New Pilot has paired Cancel/Begin actions. Open Pilot uses an embedded, themed file-list chooser rather than the host's modern native sheet. Preferences, keyboard controls entered from the main menu, About EV, credits, haikus and error dialogs share the treatment. The temporary opening replay button and existing pilot/controls behavior remain available.

## Local build 0.1.193 — Bar gambling

The Spaceport Bar now has a **Gamble** button opening the original six-symbol slot machine. Bet 1,000 or 5,000 credits; a pair returns 1.3× the stake and a triple returns 3×. Reels stop in sequence. Bets settle and save as a single transaction before animation, including when leaving early. Unaffordable bets are disabled.

## Local build 0.1.194 — Native Open Pilot dialog

Open Pilot again uses the operating system's native file picker. The custom classic dialog theme no longer applies to file browsing; pilot selection, validation, and preservation of the previous pilot are unchanged.

## Local build 0.1.195 — Restored Levo arrival artwork

The arrival picture before the opening story now uses a faithful high-definition remaster of the original ocean, islands, shuttle, passing ships, and remote-video display. The complete artwork stays visible with its original scene arrangement; story timing and controls are unchanged. The built-in image generator prompt and provenance are recorded in `godot/assets/startup/art_direction.json`.

## Local build 0.1.196 — Classic port button lettering

Classic port buttons now use bundled ChicagoFLF outline lettering, keeping the classic Mac font appearance with smooth rendering. Body text remains Geneva. ChicagoFLF is by Robin Casady and is distributed as public domain; source and attribution accompany the bundled font.

## Local build 0.1.197 — Classic flight message lettering

Bottom-of-screen flight messages now use the bundled ChicagoFLF classic Mac lettering, matching the restored port buttons. This includes landing notices, recent messages, and mission/combat alerts while retaining their existing wrapping and colors.

## Local build 0.1.198 — Illustrated opening story

Painterly frontier, alien-war, Confederation, and rebellion scenes now accompany the scrolling story. Artwork is synchronized to the corresponding source text, gently drifts, and fades in and out. A dark center and outlined white text preserve readability; widescreen displays reveal the side compositions. Story wording, speed, music, and skip controls are retained. Built-in image-generation prompts and asset provenance are saved in `godot/assets/story/art_direction.json`.

## Local build 0.1.199 — Actual original game font

Recovered the original **Sillycon Plain** TrueType font (sfnt 9295, FOND 2020) from Escape Velocity 1.0.5. Classic buttons and the green flight instrument panel now use that exact font instead of ChicagoFLF and Menlo substitutes. Extraction is reproducible with `tools/extract_original_font.py`; bottom flight messages retain their classic Mac lettering.

## Local build 0.1.200 — Story-to-flight transition

Intro mode no longer creates a hidden pause menu or modal entrance animation. Finishing or skipping the opening story enters flight directly without a closing-menu flash. Startup regression checks cover both the empty intro modal and immediate overlay-free flight handoff.

## Local build 0.1.201 — Full-height story and alternating art

Story text now enters at the bottom edge and exits at the top edge of the viewport. Independently timed left and right paintings alternate by topic and hold until each side's next scene arrives. Four new paintings cover the freighter years, buying a first shuttle, Levo, and the final send-off. Portrait artwork and softly masked half-scenes keep the center readable. New built-in generation prompts are in `godot/assets/story/ending_art_direction.json`. The port's Local Leads button, heading, and references use the shorter requested name.

## Local build 0.1.202 — Oppression and civil-war paintings

Added dedicated paintings of colonial oppression and the galactic civil war to the alternating story sequence. Faction artwork uses blue Confederation livery and red Rebellion livery. Story art now has brighter midtones and stronger side illumination. Its readability mask uses screen coordinates, avoiding excess darkening when portrait art is cropped on wider displays. The center remains dark for the scrolling text. New prompts and provenance are saved in `godot/assets/story/conflict_art_direction.json`.

## Local build 0.1.203 — Clean artwork and story handoff

Story paintings now fade out before their replacement fades in on the same side, preventing double-exposure ghosting. Removed the zoom/drift effect. Finishing or skipping the story fades to opaque black, switches to flight under that cover, then fades gameplay in. Intro, replay, and painting regression checks cover the handoff and nonoverlapping artwork.

## Local build 0.1.204 — Readable story side panels and alien encounter

New portrait paintings show an actual alien attacking a colony, blue Confederation rule, and red Rebel pilots assembling beside their ship. These replace wide compositions that left only narrow fragments visible. Remaining landscape scenes use their populated outer thirds, and the inner mask gives subjects more visible width. Alternating fades stay free of same-side overlaps. Built-in image-generation prompts are recorded in `godot/assets/story/portrait_art_direction.json`.

## Local build 0.1.205 — Distinct story scenes

Fixed the same Confederation portrait appearing simultaneously on both sides. Government power, oppression, and naval imagery now occupy separate cues with distinct artwork. Widened the central readability gradient. The painting regression samples the entire story timeline to reject duplicate paintings across sides, in addition to checking same-side overlap and full-height bounds.

## Local build 0.1.206 — Balanced story artwork

Fixed the painting shader multiplying its cropped image by the original texture a second time. This caused dark, narrow-looking landscape subjects and uneven portrait brightness. Paintings now use a single texture sample with preserved vertex tint, consistent exposure, and a mirrored fade toward the text center. Verified the alien passage and other scenes at standard and ultrawide sizes.

### Current local Mac package: 0.1.206

The complete 0.1.206 update passed **113/113 regression scripts**. The local signed app and installable ZIP are in `builds/`; see [build validation](research/reports/RELEASE_0_1_206.md) for the archive checksum and validation scope. The GitHub download links above continue to identify the last published release.

## Local build 0.1.207 — Escape menu to Main Menu

The Escape menu now places a clearly labeled **Main Menu** button immediately below Resume Flight. It saves the current pilot before returning to the title screen. If saving fails, the player stays paused and sees an error instead of silently leaving flight.

## Local build 0.1.208 — Consistent gray menu button fonts

Audited gray in-game menu buttons and applied original Sillycon lettering to map controls, autopilot selections, and shared button/dropdown/checkbox theme defaults. Existing classic service buttons retain the same font. Main-menu paper dialogs and body text keep their separate original-style typography.

## Local build 0.1.209 — Centered publisher logo

Centered the Ambrosia artwork vertically within its startup canvas, giving it equal top and bottom margins at every window aspect ratio.

## Local build 0.1.210 — First two vintage-poster story paintings

Restyled only the opening frontier and alien-attack paintings as the first preview of a bold vintage space-adventure poster direction: graphic shadows, electric blue rim light, warm orange accents, and hand-painted illustration. The remaining story images are retained for comparison. Original versions are preserved as sibling assets. Built-in generation prompts and reference roles are recorded in `godot/assets/story/poster_art_direction.json`.


## Local build 0.1.211 — Complete vintage-poster story artwork

Restyled the ten remaining opening-story paintings to match the approved vintage theatrical poster direction, with blue Confederation and red Rebellion subjects. All thirteen story cues now use the poster artwork, including the pilot's first ship, Levo and the final send-off. Landscape originals have portrait replacements for consistent side framing; the existing inward fades and independent scene transitions are retained. Original assets remain available. Built-in image generation prompts and source provenance are saved in `godot/assets/story/remaining_poster_art_direction.json`.

Validation: all three targeted story/startup/replay checks passed. Native-rendered standard and ultrawide story captures were reviewed; the macOS app was rebuilt.


## Local build 0.1.212 — Consistent in-game shuttle artwork

Corrected the frontier, first-ship, Levo journey and final send-off poster paintings to use the actual Shuttlecraft model's compact silver hull, blue canopy, integrated vented rails and small paired rear engines. Removed the invented large round pods, wings and fins. The Levo arrival illustration uses the same model while preserving its existing rendered ocean scene and instrument frame. Built-in image-edit prompts and references are recorded in the story and startup `shuttle_art_direction.json` manifests; `tools/capture_shuttle_reference.gd` captures the design directly from the game.

Validation: three targeted opening/story checks passed, with native standard and ultrawide rendering reviewed. macOS app rebuilt as 0.1.212.


## Local build 0.1.213 — Riches and dangers opening painting

The first story illustration now depicts an explorer discovering glowing mineral deposits above a prosperous trading port, with hyperspace arrivals and an ominous alien vessel. It matches the vintage poster treatment and replaces only cue zero; the later frontier/shuttle painting remains unchanged. Built-in image generation prompt and reference are recorded in `godot/assets/story/riches_art_direction.json`.

Validation: three targeted opening/story checks passed; native standard and ultrawide framing reviewed. macOS app rebuilt.


## Local build 0.1.214 — Alien Threat achievement

Added a dedicated Alien Threat badge for the original Alien investigation and cruiser finale: Rebel missions 184–189 or Confederation missions 190–194. Each route contributes its own milestone fraction; completing either full chain awards the badge, including existing completed saves. Clicking an incomplete badge follows the selected faction's prerequisites, current mission objective and navigation destinations. The existing overall story calculation remains unchanged because these missions already belong to the military story.

Validation: Alien achievement, existing achievements, guidance, both campaign routes and fleet jump checks passed (5/5). Fleet behavior is unchanged.


## Local build 0.1.216 — Exact mission contact guidance

Badge guidance for missions offered at one specific world now identifies other landing sites in the same system where that offer will not appear. When already in the contact system, bar guidance supplies the exact planet-selection hotkey and auto-landing steps. Rescue Rebel Spy is offered at Sirgil III, not neighboring Sirgil Starport. Added regression coverage that verifies both the exclusion and actual bar presentation at the correct planet. Three targeted guidance/bar checks passed.


## Local build 0.1.217 — Controller support

Keyboard and standard gamepads now work together, including macOS DualSense devices through Godot's SDL mapping. Left-stick steering is analog with a 22% dead zone; vertical stick motion supplies thrust / retrograde. R2 fires the selected weapon, L2 the secondary weapon, L3 afterburner, R3 face-target, Cross land / launch, Square board, Triangle cycle targets, Circle cloak, L1 / R1 cycle weapons, D-pad up jump, right map, left ship hail and down select the next world. Create opens fleet, Touchpad opens the journal, and Options pauses. Holding R3 adds D-pad next-destination / autopilot / world-hail / information and Circle secondary-safety commands.

In menus, the left stick moves a highlighted pointer and Cross clicks; D-pad selects buttons, the right stick scrolls, and Circle / Options returns. Map targets use the pointer, L1 / R1 zoom, and Triangle cycles destinations. Name/file text entry still uses the keyboard. The Keyboard & Controller screen documents the complete layout. Controllers reconnect without restarting; disconnect, focus loss and mode changes clear held input. Keyboard bindings remain independent and controller shortcuts follow rebound actions.

Validation: eight targeted controller, keyboard, firing, menu, startup and font scripts passed; native-renderer controller pointer activation and help layout were checked. No physical controller was connected, so Bluetooth DualSense hardware mapping and feel still require a playtest.


## Local build 0.1.218 — Controller map planning

Right stick pans the map in both axes without changing zoom. Left stick retains the pointer; Cross inspects the pointed system without erasing a planned route. Square adds the selected destination, finding connected intermediate jumps from the current route endpoint. This supports both normal jumps (next hop selected) and chain jumping (final destination selected). L1/R1 still zoom, Triangle cycles destinations and Circle returns to flight. Added an on-map control legend and updated the controller help. Targeted controller, map and chain-jump tests passed (3/3), plus native window route and pointer checks.


## Local build 0.1.219 — Controller landing-target gesture

Hold Cross in flight and flick the right stick left/right to cycle backward/forward through landing targets, including stations. Each flick selects one target; return the stick to center before the next flick. Releasing Cross after cycling does not land or auto-land. A normal Cross tap still requests landing and a double-tap still starts auto-landing; flight landing input now resolves on release so it cannot land before the player performs the target gesture. Disconnect, focus loss and mode changes cancel a pending hold. D-pad down remains a target-cycle shortcut. Updated controller help. Four targeted controller, auto-landing, keyboard and map checks passed.


## Local build 0.1.220 — Directional controller focus and scrolling

D-pad menu navigation now follows screen geometry: left/right select along rows, up/down along columns, and edges do not wrap into unrelated rows. Selection stays within its scrolling group where possible and explicitly scrolls every enclosing ScrollContainer into view. Gold focus outlines are clipped to the viewport and ancestor clip bounds. Shipyard and mission ItemLists now support internal D-pad selection with automatic scrolling, and long text panels can be scrolled with the D-pad. Right-stick scrolling targets the pointed or selected scrollable area (including text and item lists), with a fallback for menus containing one main scrolling panel.

Validation: six targeted controller, navigation, outfitter, achievements, fleet and shipyard checks passed. Native-renderer navigation tests also passed, including inspection of the outfit grid at its bottom.


## Local build 0.1.221 — Faster Sidewinder reload

Halved AIM-9 Sidewinder reload from 100 to 50 original weapon ticks (approximately 1.67 to 0.83 seconds). The shared weapon definition applies to both single fire and Maverick multi-target volleys.


## Local build 0.1.222 — Left-stick landing selection

Moved the hold-Cross landing-target gesture from the right stick to left-stick left/right flicks. Controller steering and thrust are suppressed while Cross is held for landing selection; normal keyboard control remains available. Tap / double-tap landing and right-stick map panning remain intact. Controller help updated.


## Local build 0.1.223 — Held D-pad navigation

Menu D-pad navigation now repeats while held: immediate first movement, 0.35-second initial delay, then one step every 0.10 seconds. Repeated movement uses the same directional selection and scroll-following behavior as individual presses. Releasing the direction, changing screens, disconnecting, losing application focus or returning to mouse input stops repetition. Flight D-pad actions remain single press. Three targeted controller/navigation/keyboard checks passed.


## Local build 0.1.224 — Clean D-pad selection outline

Hide the controller crosshair while D-pad focus highlights a menu item. The gold outline remains; moving the left-stick pointer clears focus and restores the crosshair.


## Local build 0.1.225 — Hyperspace exhaust warm-up and F-14 smoke

Hyperspace exhaust starts blue for one second before turning orange. Only the F-14 Tomcat leaves world-space smoke trails while its orange afterburner is active; ordinary ships emit no smoke. Smoke particles expand and fade over one second and stop spawning when the burn stops. This applies to manual F-14 afterburning and hyperspace, with shared bounded particle rendering. Missile smoke retains its existing lifetime.


## Local build 0.1.226 — F-14 machine-gun damage

Tripled the F-14 M61 machine gun's armor and shield damage (MassDmg 5→15, EnergyDmg 3→9). Fire rate and ammunition behavior are unchanged.


## Local build 0.1.227 — Return controller focus to launcher

Controller activation remembers the launching button by screen and stable identity. Returning from a child menu restores that selection even when the parent menu was rebuilt; nested views restore in reverse order, and same-screen badge details restore their launching card. Restored items are revealed within scroll containers. Existing D-pad outline-only highlighting remains. Four targeted controller, navigation, guidance and pause checks passed.

## Local build 0.1.228 — Hyperspace interrupts kill music

Starting hyperspace stops either Maverick kill celebration track before the hyperspace music begins.

## Local build 0.1.229 — Continue D-pad selection after choosing equipment

Activating a menu item restores controller focus immediately, so the next D-pad direction continues from the selected card instead of restarting at the first slot.

## Local build 0.1.230 — Commodity list typography

Commodity names use the surrounding exchange text font; Buy, Sell and Leave retain the original button font.

## Local build 0.1.231 — Clean menu panel animation backdrop

The title backdrop explicitly covers its baked-in open panels before drawing the animated panels, including when returning from gameplay. Loading artwork remains unchanged.

## Local build 0.1.232 — Controller-friendly pilot picker

Open Pilot uses a classic Mac styled modal listing valid saved pilots by name, ship and system. The D-pad selects and scrolls pilots, Cross opens one, and Circle cancels. File paths and unrelated files are hidden.

## Local build 0.1.233 — Immediate pilot list navigation

Opening the pilot picker preserves its list focus, so the first D-pad Up/Down changes the pilot immediately. Open Pilot also has the classic thick default-button border.

## Local build 0.1.234 — Configure controller buttons

Set Prefs → Keyboard & controller now includes editable flight controller bindings. Select a controller binding, then press a button or trigger; assigning an occupied input swaps the two actions. Preferences persist across launches, and controller defaults can be restored separately. Options remains pause/cancel, menu controls remain consistent, and analog stick movement stays unchanged.
