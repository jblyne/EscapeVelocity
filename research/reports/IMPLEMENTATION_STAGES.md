# Original-game completion stages

Requested 19 October 2026. This is a staged implementation plan; only stages explicitly marked complete have shipped. The 18 October parity audit supersedes older missing-feature notes.

## Stage 1 — Freight and boarding: implemented

- Commodity purchases and boarding salvage fill the flagship, then persistent escort holds. Commodity sales draw from escorts first. Mission cargo remains aboard the flagship.
- Each escort owns its six-commodity manifest. Saves validate integer quantities against that hull's hold size; older saves default to empty escort holds.
- Escort loss removes its cargo; release and unpaid departure leave its cargo aboard the independent ship. Flagship takeover transfers its manifest only when both manifests and mission cargo fit. Other escorts retain theirs. Surviving escorts retain their cargo through player escape-pod rescue.
- Boarding ammunition transfers finite compatible rounds into installed launchers, respecting outfit limits and equipment mass. Donor magazines decrease, ordinary firing consumes the recovered rounds, and transfers use the existing self-destruct risk.
- Port commodity exchange shows combined capacity and quantities. Fleet management shows per-carrier freight and release/loss consequences. Boarding exposes Take Ammo and combined freight space.
- World hailing was already implemented: H opens the selected world's channel, including landing status and tribute. It was incorrectly listed as absent in an earlier conversational audit.

These freight allocation and salvage rules are explicit remake behavior; exact original-engine allocation/limits still need reference comparison.

Validation: `godot/tests/test_parity_stage1.gd` exercises actual port trading, carrier loss/release, save/reload, malformed manifests, boarding, ammunition conservation, equipment capacity and ordinary firing. Fleet management, communications, release, shipyard, ejection, world activity and base-game regressions accompany this stage. The older release test was updated for the current persistent fleet record format and in-place release behavior.

## Stage 2 — Controls and pilot modes: implemented in 0.1.44

Add persistent configurable flight controls, original-keyboard presets, conflict handling and restore defaults. Add a separately selectable strict pilot mode with clear creation-time rules and appropriate save/death behavior. Confirm the original strict-mode semantics from the manual/executable before presenting them as original behavior; preserve existing pilots and the normal remake mode.

Acceptance: configured actions work in real input events; shortcuts do not conflict with menu navigation; bindings survive restart; strict-mode death/loading cannot bypass its documented rules.

## Stage 3 — Exploration and environment: implemented; exact reference timing pending

Compare existing visited/surveyed/adjacent map rules with the original, then implement confirmed visibility gaps. Investigate environmental-hazard claims against original EV 1.0.5 resources and executable before adding mechanics; do not import Override/Nova hazards or invent missing original features.

Acceptance: reference scenarios cover unvisited, charted, hidden and mission destinations; confirmed environmental effects behave consistently across travel, pause and save/load.

## Stage 4 — Economy and services: source bands and default prices implemented; equipment, shipyard, hiring, wage and refueling rules implemented in 0.1.45

Replace the current deterministic prototype commodity price formula with verified original commodity/port flag rules. Verify refueling, repair, outfitter resale, hiring wages, tribute and day-based changes against original play. Keep intentional user-requested remake options explicit.

Acceptance: representative ports and event changes match recorded reference cases; no trading, payroll, repair or reload duplication; older saves migrate safely.

## Stage 5 — Original secrets: partially implemented; add-ons excluded by user

Investigate Satellite of Love and remaining title-key effects with source evidence. Add-on compatibility is excluded from the current scope at the user’s request.

Acceptance: confirmed secret triggers reproduce their reference effects; base content remains recoverable.

## Stage 6 — Fidelity and campaign verification: source recovery rules and mission edge-case investigation implemented; controlled manual comparisons pending

Record original-executable reference cases for flight, combat, AI, encounter timing, cloak consumption, rescue consequences and escort economics. Resolve mission 224 PickupMode 5 and mission 228 ReturnStel -5. Perform manual campaign playthroughs in addition to existing automated routes, and tune discrepancies with reproducible comparisons.

Acceptance: each claimed match has a recorded original reference and remake verification. Intentional graphical, audio, cheat and usability differences remain documented separately.


0.1.44 implementation evidence, numerical findings, checks and the remaining verification limits are in PARITY_EXPANSION_2026-10-19.md. Stage 6 is not marked complete by automated campaign tests.

0.1.45 closes the source-backed service formulas and records the mission edge-case investigation in ORIGINAL_FIDELITY_0_1_45.md. Exact real-time AI/cadence and manual original campaign comparisons remain open.

0.1.46 restores source-backed mission cargo-scan eligibility, range and penalty handling, with focused failure/save regressions. ORIGINAL_SCANS_0_1_46.md distinguishes those confirmed rules from the still-unmeasured original acquisition and auxiliary-arrival cadence.

0.1.47 adds the separate source randomized auxiliary arrival counter and verifies encounter reset, duplicate prevention and finite losses across reload. ORIGINAL_AUXILIARY_ARRIVALS_0_1_47.md records the nominal 60 Hz conversion assumption; exact original real-time cadence and manual campaign comparison remain open.
