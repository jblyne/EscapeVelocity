# Steel-world reconstruction — 0.1.180

Destroyed worlds retain their historical destruction record, with a per-world `destroyed_at` game-day timestamp. Recovery uses the campaign's existing calendar; ordinary and chain hyperspace advance it by the normal hull-dependent number of days. Menus or real-time waiting do not advance game days.

- Day 0: debris only, no landing or gravity body.
- Day 1 onward: progressive, landable steel framework.
- Day 20: mostly skeleton; four-stage artwork phase 1.
- Day 40: additional hull plating; artwork phase 2.
- Day 60: habitats and soil/water reclamation on planets/moons; artwork phase 3.
- Day 80: completed steel shell/facility, retained reclaimed soil and water areas on planets/moons; artwork phase 4.

The live structural/plating coverage grows with each game day. Stage pictures represent the 20/40/60/80-day milestones; daily intermediate geometry is not a new painted picture. Late soil and water occupy clustered engineered areas while much of the surface remains steel. Landing scenes show matching soil plots, reservoirs and, at completion, planted rows. Stations retain steel construction.

Reconstruction docks permit landing even with hostile standing, while normal approach/landing-speed requirements remain. Original port services resume. Mission failures and canceled tribute from the destruction are not reversed. Historical fear, achievements and reputation consequences remain. A subsequent destruction restarts the timer, retaining a single historical world entry. Steel megastructures use metal-compatible explosion/breakup effects rather than the old natural-planet crust shader.

Existing saves without timestamps begin recovery on their saved campaign day during migration; the old save format did not record the actual destruction day. Save validation rejects invalid/unrecognized/future dates. JSON world IDs are normalized before membership checks, fixing actual disk reloads for active ultimatums as well as new destruction timestamps. The bribe regression now verifies that loading actually replaces the pilot and compares scheduled fractional times with serialization tolerance.

## Artwork

`godot/assets/reconstruction/manifest.json` lists **856 unique WebP images** for **107 identities**: four orbital portraits plus four landing scenes per planet, moon or station. The live and rendered structures share `scripts/rebuilt_world.gd` and deterministic world-ID geometry, panel placement, colors, docks and terrain. Original intact-world landing art remains untouched. Rebuilt landing screens use the new pictures; map reconstruction tooltips use the corresponding orbital portraits.

Materials `steel_panels.png` and `reclaimed_soil.png` were made with the **built-in image-generation tool**, then copied into the project. Exact final prompts and provenance are in `art_direction.json`. The chosen approach was unique 3D-rendered world/stage pictures using generated materials, not 428 individually AI-painted scenes. `tests/render_reconstruction_art.gd` reproduces the images; `tools/audit_reconstruction_art.py` checks full identity/stage/view coverage and rejects duplicate image hashes.

## Verification

- Full regression run: **109/109 Godot scripts passed**, zero failed scripts; logs and manifest in `builds/acceptance-0.1.180/`.
- New reconstruction test: **1,017 checks**, passing headless and native-rendered runs. Covers day 0, 1, 19, 20, 21, 39, 40, 41, 59, 60, 61, 79, 80, 81 and 200; actual landing on a planet and station; JSON restoration/migration; invalid dates; re-destruction; orbital tooltip data; late terrain geometry; and all 856 artwork resources.
- Artwork audit: **107 worlds, 856 distinct images**, complete four-stage/two-view coverage. Mature terrain calculation confirms nonzero soil and water coverage for every non-station identity.
- Native screenshots at `/tmp/ev180-landing-20.png`, `-40.png`, `-60.png`, `-80.png` inspect actual landing-screen usage.
- Standalone Mac version **0.1.180** passed strict deep ad-hoc signature verification and loaded a completed rebuilt Earth from an actual JSON pilot, including its soil/water landing image and operational services (`/tmp/ev180-packaged-landing.png`).

This is a local Mac build update; no new GitHub release was requested for this change.
