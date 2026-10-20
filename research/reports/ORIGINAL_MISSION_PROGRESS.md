# Original-game reconstruction: mission/progression update

## Verified reference

- Project's original Escape Velocity 1.0.5 resource dump: 116 missions, 54 outfits, 27 ships, 108 systems.
- Matt Burch, **The Escape Velocity Resource Bible**, revision 18 October 1996, preserved in [EVPluginPackage.sea.hqx](https://archive.org/download/EscapeVelocityPluginCollection/EV.zip/EV/Plugins/EVPluginPackage.sea.hqx). Read the original Word-format text from the archive; do not confuse this with the later Nova engine's mission semantics.
- Original local mission descriptions confirm the three special equipment rewards and their timing.

## Implemented in this update

- Mission computer, spaceport bar, flight journal, original offer/briefing/completion text, destination map selection, abandonment, and eight active mission slots.
- Interpreter for all 116 source records: faction/location availability, combat/legal requirements, randomized offers stable per visit, set/clear prerequisite bits, cargo stages, deadlines, completion/failure flags, government rewards and clean-record payouts.
- Special and auxiliary encounter groups from source encounter types. Kill, disable, board, rescue, observe and escort objectives. Chasing off a target can be satisfied by destroying it or forcing its retreat.
- Persistent per-actor health, boarding and destruction state; mission escorts follow between systems. Finite/infinite auxiliary populations and auto-aborting encounter missions.
- Cloak on acceptance of mission 164; particle beam on completion of 170; tractor beam on completion of 235. Failing/abandoning 164 removes the loaned cloak if it was newly granted.
- Cloak key K, translucent hull, no enemy target acquisition/guidance or scans while active, shield/fuel consumption and disabled player firing. Unguided shots can still hit.
- Mission bits 61 and 66 gate military equipment and hulls. Bit 73 unlocks the alternate Kestrel. Port technology restrictions still apply. Mission-only devices are visible with an explicit reward-only notice, not sold at ordinary shops.
- Original purchasable ship classes, stock loadouts, cargo/equipment limits, shields/armor, quarter-value trade-in, mission equipment transfer and save validation. Zero-armor fighters remain alive while shields hold.
- Backward-compatible, validated campaign save extension. Combat rating uses the crew totals of destroyed ships, as documented in the Bible.

## Validation and limits

Automated checks resolve destinations for every mission and exercise every source objective combination through the engine. Separate integration cases cover acceptance, mutual exclusion, original reward sequences, real boarding, actual NPC destruction, cloak behavior, deadline failure, duplicate reward prevention and JSON save round trips. Shipyard tests buy all hulls available at source shipyards, verify their stock loadouts/save round trips and preserve mission equipment. These are **not 116 complete manual campaign playthroughs**.

Two source anomalies need original-executable confirmation: mission 224 uses undocumented PickupMode 5 (treated as pickup on acceptance, matching its text), and mission 228 uses undocumented ReturnStel -5 (treated as its originating port, matching its return briefing). Missing travel/return destinations use the existing explicit destination for cargo delivery; this is necessary for the passenger contracts and Escape Astex.

## Still needed for full original-game parity

This update is not a claim that the entire original game is recreated. Remaining work includes:

- Full manual original-executable comparison, exact encounter/scan timing and precise combat balance. Delayed arrivals, original special-ship names and chase-off retreats are implemented; nine campaign routes pass automated progression checks (see ORIGINAL_PARITY_AUDIT.md).
- All outfits listed in the old gap table are implemented, including player pods and auto-ejection; see ORIGINAL_PARITY_AUDIT.md for recovery rules and original-parity limits.
- Exact commodity/service rules remain incomplete. News/disaster events, faction landing refusals, planetary domination/tribute and special person encounters beyond Hector are now implemented; see ORIGINAL_WORLD_ACTIVITY.md and ORIGINAL_ENCOUNTERS_AND_EXTRAS.md.
- Original discovery/visibility rules, environmental hazards, strict pilots, configurable original controls and plug-in compatibility.

Existing user-requested cheats, larger fuel reserve and custom combat features remain intentional remake additions.

## 0.1.45 follow-up

Original equipment/shipyard/hiring/refueling formulas, integrity recovery, pod rescue and the two mission-field investigations are updated in [ORIGINAL_FIDELITY_0_1_45.md](ORIGINAL_FIDELITY_0_1_45.md). That report supersedes the related prototype rules and unresolved notes above; full manual campaign and AI timing comparisons remain open.
