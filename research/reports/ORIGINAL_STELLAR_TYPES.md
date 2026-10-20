# Original stellar object types — v0.1.12

The original game explicitly distinguishes planets, stations, and moons. This mapping comes from the locally extracted Escape Velocity 1.0.5 resources, not object-name guesses.

- `EV Data.rsrc`: each `spöb` record has a numeric `Type`.
- `EV Data.rsrc`, `STR# 1100` (named **Stellar Types**): 34 labels in zero-based Type order.
- `EV Graphics.rsrc`, `spïn 300–333`: corresponding sprite IDs, masks, and frame sizes. The labels and graphics match the classification. Original sprites were inspected alongside these records.

Earth (`spöb 128`) has Type 0, **Class M planet**. Stardock Alpha (`spöb 129`) has Type 26, **Type 3 station**. Luna (`spöb 132`) has Type 28, **Class D moon**. Mars (`spöb 130`) has Type 20, **Class E planet**.

The catalog contains **75 planets, 17 stations, and 15 moons**. Station Types 24–27 are mechanical objects; moon Types 28–33 include rocky and habitable varieties. The previous renderer ignored these classifications and used a generic planet model for every object. Its `Type < 26` size heuristic also misclassified two station types.

## Source mapping

| Type | Original label | PICT sprite | Frame size | Examples |
| ---: | --- | ---: | --- | --- |
| 0 | Class M planet | 2000 | 80×75 | Earth, Palomino, Adhara |
| 1 | Class M planet | 2001 | 80×75 | New Providence, George's World, Hera |
| 2 | Class K planet | 2002 | 80×75 | Capella, New Columbia, Lauralee |
| 3 | Class M planet | 2003 | 80×75 | Maxwell's Purchase, Tabletop, Virgo |
| 4 | Class K planet | 2004 | 80×75 | New Istanbul |
| 5 | Class W planet | 2005 | 80×75 | Hodgson's World, Beeblebrox, Ursa Minor Beta |
| 6 | Class W planet | 2006 | 80×75 | Levo, Diphidia II, Opal |
| 7 | Class W planet | 2007 | 80×75 | Murphy's World |
| 8 | Class W planet | 2008 | 80×75 | New Britain, Palshife, Scorpio |
| 9 | Class W planet | 2009 | 80×75 | Plateau |
| 10 | Class D planet | 2010 | 80×75 | Dune, New Sahara, Sauron |
| 11 | Class K planet | 2011 | 80×75 | Landfall, Clotho Prime, Quake |
| 12 | Class F planet | 2012 | 80×75 | Atropos, New Bavaria |
| 13 | Class F planet | 2013 | 80×75 | Samson's Planet, Akio, P-1249 |
| 14 | Class T planet | 2014 | 80×75 | P-4812 |
| 15 | Class T planet | 2015 | 80×75 | Master's Planet |
| 16 | Class G planet | 2016 | 80×75 | P-6564 |
| 17 | Class G planet | 2017 | 80×75 | Sirius III, Enyo's World, Clotho II |
| 18 | Class G planet | 2018 | 80×75 | Spica, Zaxted |
| 19 | Class E planet | 2019 | 80×75 | Tau Ceti IV, Hikeeba, Pollux VI |
| 20 | Class E planet | 2020 | 80×75 | Mars, P-8457, Turin V |
| 21 | Class D planet | 2021 | 80×75 | Torgo Prime, Alkaid, Propus VII |
| 22 | Class D planet | 2022 | 80×75 | Orion, Armstrong, Darven |
| 23 | Class R planet | 2023 | 80×75 | Northstar, Thanos IV |
| 24 | Type 1 station | 2026 | 48×48 | Antares Station, Blackthorne, Nexus Outpost |
| 25 | Type 2 station | 2028 | 48×48 | Sirius Station, Zaxted Starport, Port Oread |
| 26 | Type 3 station | 2030 | 48×48 | Stardock Alpha, Sentinel Station |
| 27 | Type 4 station | 2032 | 48×48 | Enyo Fuel Refinery, Syntex Refinery |
| 28 | Class D moon | 2034 | 24×24 | Luna |
| 29 | Class M moon | 2035 | 24×24 | New Scotland, Emerald |
| 30 | Class M moon | 2036 | 24×24 | Alkaidion, New Ireland, Rupert |
| 31 | Class K moon | 2037 | 24×24 | Hunter, Endor, Evildrome |
| 32 | Class W moon | 2038 | 24×24 | Merlin, New France, New Japan |
| 33 | Class E moon | 2039 | 24×24 | Pegasus, Ruby |

## Modern rendering

`tools/build_catalog.py` now preserves the labels and sprite metadata as `stellar_types`. Original object fields, IDs, positions, system links, and custom-picture fields are unchanged. `stellar_models.gd` chooses a procedural 3D model from that data:

- Four station families: ring station, twin-ring station, Stardock command saucer with docking pods, and triangular refinery.
- Luna and gray Class D bodies: cratered rock, without oceans, clouds, or atmosphere shells.
- Mars and Class E bodies: reddish rock. Class M/W/K, frozen, cloud/gas, and ringed worlds use colors and surface treatments guided by the original sprites. Habitable moons remain habitable-looking; moons are not all forced to gray.
- Modern planet radius stays 100 world units. Original frame-width ratios produce station radius 60 and moon radius 30, used consistently by the rendered body, navigation brackets, landing, and hyperspace clearance. Station landing remains a circular frame-based approximation around the model.
- Scanner stations use a square marker; moons use smaller dots.

The modern geometry, palettes, crater patterns, gas bands, and surface details are new artwork informed by the original classification and sprites. This is not a pixel-for-pixel rebuild or a claim that every world has a scientifically exact surface map.

## Verification

Fifteen stellar checks cover all 34 type mappings, all 107 objects, model construction, the named Sol objects, station docking, moon landing boundaries and speed restrictions, and save/load preservation. The existing connected-route clearance sweep now uses the same type-derived radii as the game. Visual captures are in `builds/stellar-sol.png` and `builds/stellar-types.png`; decoded original reference sprites are under `research/decoded/stellar-reference/`.
