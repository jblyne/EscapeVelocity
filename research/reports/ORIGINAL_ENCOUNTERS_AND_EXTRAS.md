# Original encounters and title extras

Implemented from the local Escape Velocity 1.0.5 resource forks:

- Import all 220 përs records and 66 STR# tables into the catalog.
- Rare named traffic, with source hulls, faction, loadout modifications, shield multiplier, credits, dialogue, mission-bit/system restrictions, grudges and escape pods. Hector retains his dedicated implementation.
- Ship-linked contracts through hail or boarding, including named escort substitution. Ship-only missions no longer appear in port mission lists.
- Original mission ship names replace generic placeholders in briefings and spawned objectives.
- Persistent encounter and forklift-unlock state; older saves remain compatible.
- Original credits and haiku artwork available through About EV. Option-clicking the title opens the original MST3K parody credits. At the MCB 4:35 A.M. credit, Control–Command–Option–Shift–F grants the current pilot the forklift and plays the recovered KillWithForklift sample.

Extraction is reproducible with tools/build_catalog.py and tools/extract_original_extras.py. Source: original EV Data, EV Titles, EV Sounds and Escape Velocity executable resource forks. Historical title shortcut reference: https://escapevelocity.neocities.org/ev/archive/help-tips/

Validation:

- test_campaign_routes.gd: 151 checks across Rebel and Confederation recruitment through their alien finales, boarding objectives, rewards, and disk reload after each step. Uses a qualified veteran pilot and automated combat actions; not a manual combat-balance playthrough.
- test_original_encounters.gd: 174 checks covering source encounters, original dialogue, duplicate prevention, grudges, saved state, legacy saves, ship-linked contract acceptance, recovered credits and persistent forklift unlock.
- test_ship_interactions.gd: 73 regression checks.

Fidelity limitations:

- The named-character system has been completed; see ORIGINAL_NAMED_CHARACTERS.md for coverage and remaining timing/fidelity boundaries. Conditional records require their appropriate mission bits and systems. Credit-scroll speed remains reconstructed.
- The haiku artwork is original; its explicit About button is a modern access route, not a claim about its original secret key sequence.
- Satellite of Love, additional title-key effects, disaster/news mechanics, and a full manual story/combat playthrough remain unverified or incomplete. No substitute Satellite of Love ship or invented original stats were added.
