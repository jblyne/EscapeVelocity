# Phase 4 — Fighters and fleet lifecycle (0.1.166)

21 October 2026. Base-game work, preserving the requested Maverick loadout/volleys, fighter warp-follow behavior and current control bindings.

## Source comparison

The recovered original manual (`research/decoded/original-manual.txt`, lines 694–719) distinguishes escorts from bay fighters. Paragraph 703 establishes free fighter operation after purchase and docking to refuel, repair and rearm. The command table distinguishes formation, docking, hold and explicit target attack. These functions are exposed through the existing modern fleet menu; current conflicting keyboard bindings remain intact.

Original hull resources provide all weapon slots, mount counts, finite ammunition, durability, acceleration and turn rate. Fighters now use the full stock weapon arrays instead of only slot zero. The original launch routine at PPC 0x1c9c4 copies the parent's velocity components at 0x1cae8–0x1cb14 and assigns its follow owner at 0x1cd24–0x1cd38. Carrier launches now inherit heading/motion and retain a specific parent and bay weapon. Docking at 0x50bc–0x5118 matches a bay and increments that parent's fighter stock once before retiring the flight contact; the remake now implements that recovery path. The decoded checksum-identifiable executable is the same reference used in Phases 2 and 3.

## Delivered behavior

- Player fighters use every source weapon slot, mount count, finite ammo pool and shared tick-based reload rules. Allied shots retain their fighter source and target instead of masquerading as flagship fire. Enemy ships can acquire player fighters, and enemy beams can damage them.
- Defend, explicit Attack, Formation, Hold and Dock orders are available in fleet management. Backspace/current recall binding still docks fighters. Formation remains passive until another order or endurance expiry. Target references reset safely on travel/load.
- Return flight uses source hull acceleration/turning and velocity-aware braking. A fighter must be close and match motion before docking; merely flying rapidly across the carrier does not instantly recover it. Physical recall is checked at 30/60/120 updates per second. Docking repairs, refuels and rearms for free, as the manual describes. Repeated recovery cannot refund twice. Losses permanently consume the craft.
- Player sorties save separately from docked outfit inventory. Damage, all finite ammo, elapsed sortie time, heading, position, velocity, bay ownership and orders are validated and retained. Reload no longer provides a free in-flight service. Existing pilots without the optional sortie field still load. Requested staggered warp arrivals remain. Changing flagship does not carry an old hull's launched fighters into the replacement.
- NPC fighters return to their actual carrier on endurance expiry, severe damage or carrier departure. Survivors replenish that bay once and undergo a short service delay; launch limits follow the carrier's source bay stock and the global contact cap. A missing parent leaves the fighter independent rather than deleting it.
- Captured/hired carrier records persist deployed wings with damage, ammo and elapsed time. Parents restore before their wings; pending children wait for contact capacity instead of disappearing. Landing recovers/services owned carrier wings before encounter refresh, preventing stock loss or duplicate rearming. Released carriers take their fighters with them. Owned carrier wings inherit fleet target/hold/recall orders; Hold brakes the ships instead of leaving them drifting.
- Fleet management shows deployed fighter count, shields, gun mounts, remaining rounds, sortie time and order. Switching off weapon cheats removes cheat-launched craft while retaining real purchased fighters.

## Tuning and comparison limits

The existing three-minute sortie clock remains remake tuning. The source launch routine copies a weapon counter into runtime 0x50; its exact endurance interpretation/cadence has not been established, and it is not guessed from the raw field. The 45-unit recovery radius, relative-speed threshold, navigation gain and three-second NPC service delay are also remake tuning. Landing recovers the wing automatically, retaining the game's established behavior. NPC orphan escape and smooth approach integration are compatible behavior rather than a complete original AI state-machine port.

The fixed modern 12-player-fighter and 32-contact limits remain. Source bay inventories constrain each NPC carrier. Hiring wages, replacement/service prices and exact original fuel/endurance timing remain their documented reconstructed models. Full manual campaign/standalone acceptance stays in Phase 6; bribes and secrets are Phase 5.

## Validation

Focused tests exercise full loadouts and mount emissions, real disk save/reload without inventory duplication, damaged/missile-spent sorties, staggered travel, motion-gated recovery, duplicate callbacks, service, losses, legacy/invalid saves, physical approaches at three update rates, beam vulnerability, and captured carrier wings across reload/travel/port service. Existing fixture assumptions that a reset or save deletes/services a wing were updated to the new persistent lifecycle.

Final validation: 1,402 checks passed across 16 suites, including 36 focused fighter checks and all nine campaign routes. Native rendering and the fleet layout were checked separately. The 0.1.166 universal Mac app was exported, signature-verified and startup-tested. No GitHub push or release was made.
