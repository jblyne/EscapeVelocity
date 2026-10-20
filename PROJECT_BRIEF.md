# Escape Velocity HD — project brief

Status: Godot 4 selected by the user. The first playable Mac prototype has flight, basic combat, the original galaxy network, landing, trading, the original mission-data engine, ship purchasing, a prototype courier contract, upgrades, and saves. Original resource data is imported; exact engine behavior and the original campaign remain ongoing reconstruction work. See [README.md](README.md) for launch instructions and limitations.

## Goal

Build a modern, single-player Mac space trading and combat game that preserves the feel of the original **Escape Velocity (1996)** while substantially improving graphics and sound. The user confirmed the original game as the reference, rather than Override or Nova.

The reference page describes an open-ended mix of combat, trade, exploration, faction choices, and expandable content. The original game's 1.0.5 archive has now been inspected directly: its embedded resource templates let us recover structured game data, including ship specifications, weapon parameters, systems, and mission definitions. Additional versions and the add-on collection remain uninspected.

## Recommended approach

Use **Godot 4 with GDScript**, with movement and combat on a flat plane and an overhead orthographic camera. The first build uses procedural 3D ships and planets, a shader-based starfield, and original synthesized placeholder sounds. Godot and the official Mac export template are stored locally in `.tools/`.

The user selected Godot after comparing engines. The Unity recommendation in earlier discussion is superseded.

Keep gameplay simulation separate from graphics and audio. Store ship, weapon, commodity, system, and mission definitions as data so tuning the game and expanding the universe does not require rewriting its core systems.

## Preserve and improve

| Area | Target |
| --- | --- |
| Flight | Reproduce the original relationship between turning, thrust, momentum, and speed limits through measured reference play. |
| Combat | Recreate readable ship encounters, targeting, weapons, defenses, and enemy behavior, then tune against the original. |
| Exploration | Travel between connected systems, discover destinations, and land to access services. |
| Economy | Carry cargo, compare prices, complete jobs, and invest earnings in ship progression. |
| Player freedom | Support different paths through trading, missions, combat, and faction relationships. |
| Graphics | Maintain recognizable silhouettes at gameplay scale; add detailed materials, planet atmospheres, engine trails, weapon effects, and restrained explosions. |
| Sound | Develop distinct engine, weapon, impact, travel, and interface sounds, with separate music and effects controls. |
| Interface | Provide readable high-resolution text, a clear map and radar, configurable controls, and reliable saving. |

Stored movement parameters, weapon settings, prices, mission conditions, and numerous other fields have been decoded from the original archive. Their engine interpretation—including time units, AI algorithms, physics integration, and special-case mission rules—still requires reference documentation, executable analysis, and gameplay validation. The reconstruction should use the recovered data as its starting point.

## First playable milestone

Create a small but complete game loop using a subset of the recovered original definitions and prototype visuals/audio:

1. Begin at a port with a starter ship and accept a delivery job.
2. Launch and fly using keyboard controls.
3. Select a connected destination on the map and travel there.
4. Encounter a hostile ship and either fight or escape.
5. Land, deliver the cargo, and receive payment.
6. Trade goods or buy an upgrade with the proceeds.
7. Save, quit, and resume with the correct ship, location, cargo, credits, and mission state.

Suggested initial scope: three connected systems, three ports, a player ship, a trader, a pirate, one primary weapon, a few commodities, one delivery mission, and one purchasable upgrade. These are proposed development limits, not counts from the original game.

Include representative graphics and sound early enough to judge the intended presentation. Expand only after the travel, combat, and economic loop is enjoyable and stable.

## Development sequence

1. **Reference and handling:** inspect original documentation and gameplay; record controls and observable behavior; build and compare the flight model.
2. **Playable loop:** implement the first milestone, including saving and a native Mac run.
3. **Presentation:** establish a consistent ship and environment style, improve effects and sound, and check performance on the user's Mac.
4. **Progression and universe:** expand ship classes, outfits, encounters, factions, and mission chains.
5. **Expansion support:** document a modern content format. Investigate conversion of old plug-ins separately before promising compatibility.

Full original-content fidelity and automatic support for every historical add-on are separate, larger deliverables. A new engine does not automatically load those formats.

## Acceptance checks

- The complete first-milestone loop works without editor intervention.
- Ship handling remains consistent across different rendering frame rates.
- Purchases and sales respect credits and cargo capacity.
- Jobs pay only when their completion conditions are satisfied.
- Saving and loading preserves progression without duplicate rewards or lost cargo.
- The game runs as a Mac application; controls, text, sound, and effects are usable at the chosen display resolution.
- The user plays the build and compares its handling and pacing with their memory of the original; reference play resolves specific discrepancies.

## Sources reviewed

- [Escape Velocity — Macintosh Repository](https://www.macintoshrepository.org/6700-escape-velocity): original-game overview and archive inventory.
- [Unity manual — 2D and 3D projects](https://docs.unity3d.com/6000.0/Documentation/Manual/2Dor3D.html): orthographic 3D and 2D gameplay with 3D graphics.
- [Godot introduction](https://docs.godotengine.org/en/stable/about/introduction.html): engine capabilities and licensing.
- [Godot — exporting for macOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html): native Mac application export.

Sources reviewed September 20, 2026. Engine choice and milestone sizes above are project recommendations, not claims made by those sources.
