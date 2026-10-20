# Fleet management and combat update — 18 October 2026

## Playable changes

- F opens fleet management in flight or at a port. The port screen also links directly to hiring and fleet service.
- Local, nonhostile traffic types supply hire offers. Each captain has a displayed contract price and daily wage; payment occurs on game-day advances. Unpaid captains leave. Charges cannot repeat when loading a save or revisiting a menu. The existing eight-ship fleet limit remains.
- Defend, Attack selected contact, Hold position, Recall, and Release work for captured and hired escorts. Selected attack targets and hold positions are local to a system; after travel Attack falls back to defense and Hold uses the new arrival position.
- Persistent escorts now participate in normal NPC combat: original hull durability, stock weapon arrays, finite ammunition, missiles, turrets and carrier fighters. Opponents can target and destroy them. Player/fleet fire does not accidentally hit other fleet members, and the chain-jump cheat still spares allies.
- Health layers, ammunition, ownership, orders and paid-through day survive saves and travel. A destroyed escort is removed permanently. Repair/rearm service at ports charges for missing integrity and stock ammunition.
- Captured ships can become the player's flagship. A visible confirmation warns that the previous hull and equipment are abandoned. Cargo capacity is checked first; cargo, credits, mission state and the rest of the fleet remain. The captured ship's remaining ammo and damage carry over. Hired ships cannot be taken over.
- Boarding one's own fleet is blocked; fleet management is the supported interaction, avoiding freshly generated NPC inventory becoming repeatable salvage.

## Fuel and damage

Player tanks now use the original hull Fuel field plus installed tank upgrades: a new shuttle has 400 units/four ordinary jumps. Legacy saves with the 100,000-unit testing reserve remain valid and clamp to the current hull capacity. New saves record the normal fuel-rule version and reject oversized tanks. Infinite-fuel and chain-jump cheats remain available, as does the G debug refill.

NPCs maintain distinct shield and armor amounts. Original EV's damage calculation is **not** Nova's direct EnergyDmg/MassDmg interpretation. SpacePort's conversion for 30-byte EV weapon records uses:

- shield damage = max(energy + mass/4, mass)
- armor damage = max(mass + energy/4, energy)

The implementation uses integer quarter contributions. It also follows the converter's negative-shield encoding (five times the absolute value) rather than the earlier unsigned-word guess. Shield regeneration uses capacity and the source recharge field. Crossing the shield boundary applies the unused fraction of the hit to armor; the old player-only 0.8 multiplier is removed. Target information shows both layers, and panic prediction uses the same damage calculation as impacts.

Sources: [SpacePort author's converter](https://andrews05.github.io/evstuff/) (`SpacePort_main.xml`, ship conversion and 30-byte weapon branch); original local ship/weapon resources. [Archived original tips](https://escapevelocity.neocities.org/ev/archive/help-tips/) also establish hiring combat escorts.

## Reconstruction limits

Hiring availability, contract price (ten daily wages), daily wage (max(100, hull cost/1000)), service pricing, fleet limit, formation/engagement rules, fractional damage overflow and regeneration tick scaling are remake choices or reconstructions. This is not a claim of original-executable numerical parity. Escort freight holds are not yet pooled into the player's trading capacity. The legacy capture-resistance hull-launching feature and temporary cheat escorts remain intact.

## Validation

35 fleet-management checks cover hiring/payment, nonpayment departure, distinct identities for duplicate legacy hulls, source loadouts, actual combat, orders, damage/ammo persistence, paid service, safe flagship takeover, permanent losses, old/new fuel saves, EV damage conversion, armor-preserving shield regeneration and ally-safe jump wakes. Existing campaign, named-character, communications, shipyard, utility, cheats, panic-audio, flight, targeting and chain-jump suites are rerun. Fleet and takeover dialogs were rendered and visually inspected.

## 0.1.45 follow-up

Original equipment/shipyard/hiring/refueling formulas, integrity recovery, pod rescue and the two mission-field investigations are updated in [ORIGINAL_FIDELITY_0_1_45.md](ORIGINAL_FIDELITY_0_1_45.md). That report supersedes the related prototype rules and unresolved notes above; full manual campaign and AI timing comparisons remain open.
