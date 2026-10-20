# Original-game feature audit — 18 October 2026

The older status table is superseded by this audit.

| Area | Implemented behavior | Verification |
| --- | --- | --- |
| Stories | All 116 original mission records feed the mission engine, including source text, prerequisite bits, objective actors and rewards. | Mission interpreter suite: 281 checks. |
| Campaign progression | Rebel and Confederation alien finales, environmental investigation, Starbound, colony assistance, UGE, Astrodyne, Artemis bounty hunters and escort-carrier operations. | Nine integration routes, 457 checks: natural prerequisite unlocks, acceptance, travel, objective combat/boarding, completion and disk reloads. Veteran legal/combat standing and a large cargo ship are test setup; progression bits and rewards are earned. These are automated runs, not manual playthroughs. |
| Mission encounters | Source ship names, delayed arrival for ShipBehav 9/10/11, escort following, persistent actor state and chase-off retreats. Escape fails a kill objective instead of awarding a kill. | Ten focused arrival/retreat checks. |
| Named characters | All 220 source records, including Hector, Redbeard and Matt Burch; dialogue, linked contracts, loadouts, retreat, grudges and pods. | Roster suite: 956 checks; encounter suite: 174 checks. |
| World activity | News, disasters, source commodity changes, story headlines, domination battles, tribute and legal-record landing refusals. | World suite: 38 checks. |
| Equipment | Escape pods, auto-ejection, density scanner, IFF, missile jammer, regional maps, automatic refueling and fake IDs. | Utility suite: 45 checks; outfitter: 94; player ejection: 18. |

## Player survival

Purchase Escape Pod (154) and optionally Auto-Ejection System (181) at outfitters. Shift+X or the ship-information button opens a deliberate manual-ejection confirmation. Fatal combat damage automatically ejects only with both items installed; invincibility still takes precedence. A visible source-model escape pod leaves the explosion and offers rescue after three seconds.

Accepting rescue supplies a stock shuttle at the nearest inhabited port by jump distance, advances one day, loses the abandoned hull/outfits/cargo, and fails active contracts through their normal failure rules. Credits, completed campaign progress, legal records, world state and surviving escorts remain. The rescue screen explains these consequences before acceptance. Ejection cannot overwrite the last living save; the complete recovery is saved together. Loading/restarting cancels any pending pod animation.

Original outfit descriptions establish manual pod use and the auto-eject dependency. The precise rescue destination, replacement-shuttle economics, time advance and animation timing are explicit remake recovery choices, not verified original-executable behavior.

## Encounter reference and remaining verification limits

The SpacePort converter's original EV/EVO mission conversion (SpacePort_main.xml, `case misn`) maps ShipBehav >=9 to behavior minus ten and ShipStart=1. The compatible Nova resource reference defines ShipStart=1 as delayed hyperspace arrival. This implements that distinction with a three-second flight-time delay; menus pause it. Source: [SpacePort author/source](https://andrews05.github.io/evstuff/) and [resource reference](https://andrews05.github.io/evstuff/guides/evnbible.html). This does not import Nova's incompatible mission reward/flag semantics.

Chase-off enemies start retreat at 35% remaining combined health while still operational, and depart after eight seconds and 1,800 units separation. These thresholds are remake tuning. Disabled ships cannot flee, escaped actors persist as resolved, and kill/retrieval objectives do not miscount escapes as destruction/boarding.

Exact original-engine timing, combat balance, rescue consequences, and two source anomalies (mission 224 PickupMode=5, mission 228 ReturnStel=-5) still require comparison against the running 1996 executable. All listed feature categories now have working implementations; this is not a claim of byte-for-byte engine parity.

The subsequent fleet/fuel/combat update is documented in ORIGINAL_FLEET_AND_COMBAT.md. It adds hiring, fleet orders, combat-capable persistent escorts, flagship takeover, normal fuel capacities and separate shield/armor handling.

## 0.1.45 follow-up

Original equipment/shipyard/hiring/refueling formulas, integrity recovery, pod rescue and the two mission-field investigations are updated in [ORIGINAL_FIDELITY_0_1_45.md](ORIGINAL_FIDELITY_0_1_45.md). That report supersedes the related prototype rules and unresolved notes above; full manual campaign and AI timing comparisons remain open.
