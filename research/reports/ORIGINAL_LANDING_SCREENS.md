# Landing screens and updated scenery

## References

The local verified Escape Velocity 1.0.5 resources provide 34 type-indexed landscapes: `EV Titles.rsrc`, PICT 10000–10033. Stardock Alpha uses custom PICT 11000 in EV Titles; Darkstar uses custom PICT 11001 in EV Graphics. Luna explicitly overrides its type with PICT 10022. The `spob` Type and CustPicID fields select artwork; the matching `desc` resource supplies the original landing description.

The original layout is also visible in [this Stardock Alpha screenshot](https://www.myabandonware.com/media/screenshots/e/escape-velocity-yde/escape-velocity_6.jpg): large scenery at left, original descriptive paragraph at upper right, service buttons beneath it, Mission Computer below the picture, and Leave at lower right. The original manual's commodity screen (PICT 2002) supplies the exchange arrangement and its text specifies buying/selling up to ten tonnes.

## Art delivery

All **36 images** were generated separately with the **built-in image_gen tool**, using the decoded originals as visual references. Composition, camera direction, horizon placement, large silhouettes and distinctive palettes were retained while adding modern surface detail, atmosphere and lighting. These are new interpretations, not pixel-identical restorations.

Final project assets: `godot/assets/landing/10000.png` through `10033.png`, plus `11000.png` and `11001.png`. The exact prompt set and source-picture assignments are recorded in [LANDING_ART_PROMPTS.json](LANDING_ART_PROMPTS.json). The originals and their generated outputs are preserved separately. Regenerate the reference files with `python3 tools/extract_landing_reference.py`; this does not overwrite the generated artwork.

`landing_art.gd` maps all 91 landable worlds/stations through their source Type/CustPicID values. Artwork is loaded and cached on demand. The landing view preserves the original 333:271 scenery proportions and rebuilds the 600:316 dialog at twice its design coordinates, scaled to the window.

## Interaction

The landing page uses the original service names: Refuel Ship, Commodity Exchange, Outfit Ship, Visit Shipyard when available, Spaceport Bar, Mission Computer and Leave. Existing remake service availability and prices remain unchanged. Refuel Ship also retains the remake's repair service, with the exact price in its tooltip.

Commodity Exchange is a separate paused screen with a selected green row, fleet quantities, prices, Buy/Sell and Leave. Transactions buy or sell up to ten tonnes, constrained by funds, hold capacity and stock aboard; normal fleet cargo distribution remains in effect. Low/Med/High labels compare against the remake's existing base prices and do not establish original market parity.

The bar exposes bar mission offers, news/tribute and fleet hiring/management. The authored introductory courier contract moved into the Mission Computer. Escape returns from a port service to the landing page before launching; Leave/L still launches normally. No pilot save-schema changes were needed.

## Verification

`test_port_presentation.gd -- --assets` passes **229 checks**, including every landable port's artwork/text, source overrides, text wrapping, repair/payment, capacity-limited bulk trading, mission/courier access, bar/news/fleet/outfitter/shipyard navigation, pause behavior and clean departure. `-- --visual --assets` captures Dune, Levo, Stardock, exchange, bar and the 1000 × 650 window. `-- --visual --station-only` verifies a fresh station landing independently of the asset-enumeration pass.

Gameplay (115), missions (281), fleet management (35), world activity (38), outfitter (94) and shipyard (68) regressions pass. The world-activity test now enters the bar to access news; two stale outfitter expectations were aligned with the already-implemented 400-unit stock tank and converted shield recharge timing, without changing those mechanics.
