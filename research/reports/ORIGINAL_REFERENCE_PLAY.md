# Original Escape Velocity: live reference

Date: September 20, 2026.

## Working emulator

The original Escape Velocity application successfully launches and reaches active flight in [Infinite Mac running Mac OS 7.6](https://infinitemac.org/1997/Mac%20OS%207.6). The emulator was operated through the browser UI, and its title screen, credits, shuttle-naming dialog, and flight screen were visually inspected.

Launch path inside the emulated Mac:

**Infinite HD → Games → Ambrosia Software → Escape Velocity → Escape Velocity**

If double-clicks do not register reliably through automation, select the item and use **Command-O**. Finder's incremental keyboard selection also works. Allow folder contents to finish loading before selecting the next item.

This session uses Infinite Mac's bundled copy. Its exact patch version has **not yet been confirmed**. Do not assume it is byte-identical to the separately downloaded, checksum-verified 1.0.5 archive. The credits identify Matt Burch and Ambrosia Software (1996), with an unregistered status. No registration bypass was performed.

The active browser tab was retained for reference. Avoid refreshing it while relying on current session state. Infinite Mac's desktop notes describe Saved HD as the persistent disk; a pilot on Infinite HD should not be assumed to survive a new session.

## Directly observed

- The original title screen offers New Pilot, Open Pilot, Enter Ship, Set Prefs, About EV, and Quit EV.
- The new-shuttle dialog identifies a Rendelli StarDrive 805R cargo shuttle and offers the default ship name Adventurer.
- Active flight shows a ship-centered view, a separate right-hand status panel, radar, shield/fuel bars, navigation mode, weapon/target readouts, cargo space, and credits.
- The initial flight screen showed 10,000 credits and 20 free cargo units.
- The welcome message explicitly describes two landing commands: press L to request clearance, then L again to land.
- The original renders a sparse, point-like starfield. Its exact parallax rates have not yet been measured; our brighter stars and short trails remain a modern readability choice.

## Rules confirmed by the recovered 1.0.5 manual

The searchable manual is generated locally at `research/decoded/original-manual.txt` from the eleven TEXT resources in `Escape Velocity Documentation.rsrc`. These are documentary findings, not claims that every action has already been measured in the emulator.

| Behavior | Original description | Prototype status (0.1.4) |
| --- | --- | --- |
| Coasting | Thrust changes velocity; turning alone does not change the existing direction of travel. | Basic coasting is present, but numerical tuning is provisional. |
| Down-arrow | Turns the ship to face opposite its current velocity. The pilot then applies main-engine thrust to slow down. | Implemented: S/Down turns against drift without changing velocity; W/Up thrust provides deceleration. WASD turning aliases remain. |
| Landing | First request clearance and select the destination. Then fly directly over it, shed most speed, and press L again. Selection brackets indicate clearance status. | Implemented: first L grants per-world clearance (blue brackets); a second L checks position and speed. Faction-based refusals remain unimplemented. |
| Autopoint | A aligns the ship toward the selected planet. | A currently turns left as part of WASD controls. |
| Multiple destinations | 1–4 or F1–F4 select specific stellar objects. | 1–4 select a specific world. Without a selection, the first L chooses the nearest world. F1–F4 aliases remain unimplemented. |
| Hyperspace availability | Fly outward from the system center until gravity no longer prevents jumping; a navigation highlight and tone signal readiness. | A provisional 500-unit clearance from every object's visible edge is used. Exact original geometry/threshold remains unverified. |
| Jump sequence | J makes the computer use main engines to stop, align with the warp line, then accelerate/spool up into hyperspace. | Implemented: engine braking to rest, alignment to the selected galaxy-map connection, then main-engine acceleration and a provisional 2.4-second spool. J cancels, preserves drift, and uses no fuel. Exact original timings remain unverified. |
| Route planning | Shift-click connected systems to queue a route; the next destination is selected upon arrival. | Single-hop destination selection only. |
| Map knowledge | Systems and services are progressively recorded through exploration and landing. | The full original network is visible in the prototype. |

Manual evidence: TEXT 131 for flight/landing; TEXT 132 for navigation/hyperspace; TEXT 133 for multiple destinations and missions.

## Next comparison pass

Follow-up: two hyperspace jumps have now been completed and inspected. See [ORIGINAL_HYPERSPACE_OBSERVATION.md](ORIGINAL_HYPERSPACE_OBSERVATION.md) for measured screen motion, arrival distance estimates, timing limits, and the confirmed mismatch with the prototype's stationary arrival.

1. Confirm the bundled game's version, or run the verified 1.0.5 distribution in the same emulator.
2. Establish a repeatable input method and emulator speed setting before deriving frame timing. Brief automated key taps can be missed by software that polls held-key state; use controlled holds for quantitative flight tests.
3. Compare launch, drift, rotation, facing opposite motion, landing clearance, and hyperspace stages in a consistent starting system.
4. Record observed values and remaining uncertainty before changing prototype physics or thresholds.
5. Compare port services, equipment limits, combat behavior, and original mission-state transitions in subsequent focused passes.

Emulation is a working reference, not proof of behavioral parity. The subsequent 0.1.4 implementation adopts the three documented sequences above. Automated checks verify their state transitions and integration with the existing courier loop, but original-engine timing and thresholds still require measurement.
