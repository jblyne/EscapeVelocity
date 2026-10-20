# Restored utility equipment

Source: the local Escape Velocity 1.0.5 outfit records and original descriptions 3027, 3028, 3030, 3037, 3041 and 3052 in original_catalog.json.

Implemented:

- Density Scanner (155): radar blip sizes reflect hull mass.
- IFF Decoder (156): hostile ships and worlds are red; other contacts green. Without the decoder, contacts use uniform green. Detailed ship information remains accessible.
- Missile Jammer (158): reduces incoming missile (weapon 132) steering; torpedoes, player missiles and the forklift are unaffected. Cloaking and flare behavior are preserved.
- Regional Map (165): consumes the purchase to chart systems within two graph jumps. Surveyed systems persist separately from visited systems. Redundant purchases are blocked. The map displays explored/charted space, adjacent exploration options, and mission destinations; the chain-jump cheat retains the full galaxy. Map framing adapts to known space.
- Auto-Refueller (169): landing purchases a full tank at the existing fuel-service rate without purchasing armor repairs. An unaffordable fill leaves money/fuel unchanged and reports the shortage. Infinite-fuel pilots incur no charge.
- Fake ID Papers (180): consumes the purchase and clears negative Confederation reputation to zero. Other factions and subsequent crimes remain effective.

Original costs, technology restrictions, mass and installation limits apply. Older saves remain compatible. The existing enlarged testing fuel capacity remains in effect, so a nearly empty tank can still be expensive to fill.

Numeric jammer effectiveness, scanner blip scaling, map presentation, and insufficient-funds handling are remake choices; the recovered descriptions establish behavior but do not provide these engine details. Consumed map/papers purchases are explicit implementation choices rather than a claim of exact executable parity.

Validation: 45 utility-equipment checks, 92 outfitter checks, 151 campaign-route checks, classic UI regression checks, and rendered map/radar inspection. The utility test includes actual guided-projectile steering, shop availability/purchases, save validation and legacy loading. The classic UI fixture now disables ambient traffic so its combat-drill target cannot be preempted by a random hostile.

News/disasters, planetary tribute, and reputation-based landing clearance are now implemented; see ORIGINAL_WORLD_ACTIVITY.md. Escape pods and automatic ejection are now implemented; see ORIGINAL_PARITY_AUDIT.md. Remaining verification includes exact original-engine timing, Satellite of Love, and manual original-game campaign comparison.
