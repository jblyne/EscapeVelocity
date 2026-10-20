# Original fidelity follow-up — 0.1.45

Scope: continue original-game completion, excluding add-ons. This report supersedes the unresolved service-price and mission-field notes in the 0.1.44 report where explicitly addressed below. It does not certify complete engine parity.

## Economy and services

The original 1.0.5 PPC executable is the reference, decoded with `tools/unpack_ev_executable.py` and inspected using `tools/disassemble_ev_reference.py`. No external engine implementation was substituted.

- Equipment price helper 0x4a914–0x4aa10 discounts items costing at least 100 when their technology level is below the port's and both levels are at most five: `int(cost * ((100 - 3*(portTech-itemTech)) * .01))`. It then rounds down to multiples of 1,000 above 100,000, 100 above 10,000, or 10 above 100. Special technology does not receive this discount, but price rounding still applies.
- Outfitter sale 0x42300–0x42388 uses that port price. Counts at or below the visit's starting inventory sell for 80%; units above that inventory sell for the full port price. The inventory baseline survives panel rebuilds and resets on a new visit. Loading commits equipment to the existing inventory. Mission consumables and installation restrictions remain enforced.
- Ship value 0x662d8–0x6641c starts at 25% of hull cost and adds 95% of each installed outfit's quantity-times-cost, including stock equipment and excluding mission equipment. The exclusion byte is populated from outfit flag 4 at 0x24530–0x2455c. The shipyard applies the tech-price helper twice to trade-in value at 0x45b38 and 0x45b84. A new hull uses the helper once. Values cannot produce a negative purchase price.
- Hiring display 0x45cd0–0x45d54 and charge 0x448e0–0x44984 use 10% of the port-adjusted hull price. The daily debit at 0x20964–0x209d4 and player-information total at 0x4924c–0x492c4 use 1% of base hull cost per hired ship. Captured escorts remain unpaid. Loaded hired records adopt the corrected wage without changing the paid-through day.
- Refueling 0x41014–0x410a8 buys one fuel unit per credit and limits the fill to available credits. The controlled-port byte bypasses the charge. Uninhabited ports cannot refuel. Manual and automatic refueling share the same calculation. The old combined full-service helper remains for compatibility with existing internal callers; the classic button now performs fuel-only service.

Independent examples: a proton cannon costs 7,730 at Earth and an existing unit sells for 6,184. An untouched shuttle trades in for 5,610 there, including its stock laser. A Courier costs 158,000 before trade-in, costs 15,800 to hire, and costs 1,800 per day. These replace the prototype's cheaper escort wages and half-price resale.

## Integrity recovery

Original current integrity is a signed shield/armor pool: the disabled checks at 0x61d94–0x61ebc test negative integrity against armor capacity, while 0x61ed0 obtains maximum shields. The recovery path at 0x36528–0x365e4 adds truncated one percent of shield capacity on the recharge interval while the ship remains operational; there is no post-hit four-second player delay or two-second NPC delay in this path. Source ModType 5 values adjust the recharge interval at 0x61fe0–0x62080. The Shield Booster's -2 value therefore subtracts two from the base interval.

The original disable predicate at 0x61dd0–0x61e40 compares negative integrity times 100 with armor capacity times -33.333. NPCs therefore disable after losing slightly more than one third of their armor, after shields are exhausted, rather than at 15% of combined shield/armor capacity. Zero-armor fighters do not become boardable while shields remain. The same predicate applies after fleet restoration. Prize crews restore captured hulls above that boundary so existing capture functionality remains operational; the precise 70%-armor prize repair remains remake tuning.

The remake retains separate displayed shield/armor values and smooth time integration, but restores armor before adding shields. Disabled NPCs cannot regenerate themselves back into combat. Cloak still suppresses recovery. Returning from a port restores original current integrity at 0x32e80–0x32e8c; the remake fills both layers on successful landing without an invented repair charge. Exact wall-clock tick cadence still needs a controlled original-executable measurement.

## Mission edge cases

- Mission 228 ReturnStel -5: the port resolver 0x51e40 initializes its result to the originating port. The negative -5 value matches none of its special cases/ranges and returns that result at 0x52d64. The separate *system* resolver handles -5 as a neighboring system; it is not the routine used for this return field. Existing return-to-origin behavior is confirmed and covered by a focused test.
- Mission 224 PickupMode 5: resource loading copies the value unchanged at 0x53da0–0x53dbc. The acceptance pickup branch at 0x539f8–0x53a1c recognizes zero, and the travel pickup branch at 0x57078 recognizes one. Five has no established special pickup semantics. The remake deliberately retains pickup on acceptance as a repair of this anomalous source mission, consistent with the toxin-transport briefing. It is not relabeled as a newly discovered original pickup mode.

## Escape-pod recovery

The manual explicitly says pod rescue clears legal records. The executable recovery path fails active missions at 0x31f2c–0x31f78 and reinitializes ship/escort slots with a non-new-pilot call at 0x31f7c–0x31f84. The initializer sets system index zero (catalog 128, Levo) and a stock shuttle; this is Levo, not Sol. The sequence calls the day-advance routine 0x63e7c thirty times at 0x31fa4–0x31fc0. Legal records reset from each system government's InitialRec at 0x320dc–0x3215c. The remake now advances thirty days, clears the escort fleet, and restores starting legal records while preserving completed story, interaction memory, and destroyed worlds. It returns to Levo when available and uses a surviving inhabited fallback after custom world destruction. The confirmation explains these consequences. Credits are retained and no speculative replacement charge was introduced.

## Title controls and secrets

The original title dispatcher 0x4cdd0–0x4cedc maps N/O/Q/E/P/A to New/Open/Quit/Enter/Preferences/About and X to haikus. The remake now supports these menu shortcuts, only when no title dialog is active. Typing a pilot name cannot trigger secrets; Enter cannot skip the creation dialog. Existing original haikus, parody credits, forklift trigger, and Satellite of Love preview remain. No invented playable secret hull has been added.

## Live original reference

The Infinite Mac Mac OS 7.6 reference was successfully launched after using held input and checking every screen transition. The title art identifies Escape Velocity 1.0.5. A fresh normal pilot was created with the original default names Stud Beefpile / Journeyman. The title and first flight confirmed Levo as system index zero. Landing was completed and the original Levo exchange displayed Food 120 (Med), Industrial 192 (Low), Medical 600 (Med), no Luxury market, Metal 144 (Low), and Equipment 360 (Med). Those prices agree with the recovered 1.25 spread and are recorded as an independent numeric test case. The bar produced a natural offer to transport engineers to Turin V; no complete campaign route is claimed from this session. The background reference tab is retained for continued comparisons.

This is new live-reference evidence, superseding the unsuccessful launch attempt recorded for 0.1.44. It does not establish original wall-clock frame cadence or a complete manual campaign match.

## Verification and scope still open

Focused automated suites cover original service-price examples and transaction lifecycle, recovery boundaries, booster arithmetic, immediate player/NPC recovery, disabled contacts, cloaking, landing repair, old hired records, both mission anomalies, title shortcuts, and thirty-day pod recovery/legal reset. Existing campaign, services, outfitter, shipyard, fleet, freight, ejection, strict-pilot, world-killer, appeals, interaction-history, weapon-audio, and environment suites accompany the release. The classic outfitter was rendered and inspected at a 1000×650 window; pricing, selection, text, and buttons fit.

Still open: controlled original-executable observations of flight/AI/scan/encounter timing, full manual campaign comparisons, and exhaustive modifier-click secret behavior. Recovery timing remains smoothly integrated at the remake's clock rather than certified against measured original frame cadence. These are verification/fidelity limits, not claims that they were completed by the campaign automation. Legacy add-ons remain excluded.

## Automated release results

Zero failed checks in the focused service-price suite (33), recovery/disable/landing suite (14), ejection suite (23), nine campaign routes (457), mission suite (284), outfitter (92), shipyard (72), classic services (38), port presentation (45), utility outfits (45), fleet management (35), freight (34), communications/boarding (73), panic audio (110), original encounters (174), mission arrivals (11), controls/strict (16), base gameplay (115), environment/economy/secrets (1298), world killer (113), live appeals (20), interaction history (32), weapon audio (60), and cloak/jump (17). Title-menu checks also completed with no failures or script errors.

The exported macOS bundle reports version 0.1.45 and completed an isolated fresh-pilot boot. Its packaged resources passed service prices (33), combat recovery/disable rules (14), ejection (23), and title-menu checks. Test saves use temporary paths; the normal player save was not used for this verification.
