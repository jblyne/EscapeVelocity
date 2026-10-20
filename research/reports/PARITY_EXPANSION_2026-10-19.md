# Original-game completion work — 0.1.44

Scope: continue remaining original-game stages, excluding legacy add-ons.

## Implemented

- Saved configurable bindings for 21 existing gameplay actions, aliases, conflict rejection, reserved system/menu keys, defaults and a classic flight preset. Preferences are accessible from the title and pause screens. Rebound keys work in mission-map shortcuts too. F1–F4 select stellar objects. Game speed is adjustable from 0.5× to 2× and Caps Lock toggles an additional 2× flight-time multiplier. Preferences apply across pilots; tests use isolated temporary preference files.
- New-pilot name and strict-play checkbox. Strict death writes a deceased pilot atomically; the ordinary loader refuses it. Normal death retains the last living save. Auto-ejection occurs before permanent death, so equipped strict pilots can survive in their pods. Existing saves default to normal rules.
- Trading now reads source per-commodity bands and unavailable markets instead of the port-ID pseudo-price formula. Default low prices truncate base/1.25, medium uses base, and high truncates base*1.25. World events set base+delta with a minimum of five. Service displays and outfit availability respect exchange/outfitter source flags. Hostile and dominated market spread variants are reconstructed from the negative-record/controlled-port branches; the mapping of those runtime fields still warrants original-play confirmation.
- Stable asteroid fields use the original system density. Swept projectile and beam obstruction provides asteroid cover. Ships do not take invented asteroid-collision damage. Original system interference limits remote radar while preserving nearby contacts and fleet tracking. Density-to-count and interference-to-range scaling remain reconstructed, not measured original constants.
- Map goods and services follow actual port flags; hazards show source scanner interference as well as asteroids. Existing visited/surveyed/adjacent/mission visibility is retained. All 108 base system VisBit fields are -1; defensive visibility-bit filtering is now present without inventing hidden base systems.
- Satellite of Love secret shipyard illustration and original description restored. S+O+L unlocks access at the title or reveals it in the shipyard; the unlock persists. Selecting an ordinary ship restores its usual view. The implementation exposes the recovered secret preview, not an invented flyable hull with guessed statistics. X at the title opens the original haiku page. Existing parody credits and forklift unlock remain.

## Evidence

The bundled original manual states that Strict pilots cannot resume after death and recommends using an escape pod; it also documents configurable controls, game-speed preferences and Caps Lock acceleration. See research/decoded/original-manual.txt, the Preferences and New Pilot sections.

Original EV 1.0.5 PowerPC executable, unpacked read-only using tools/unpack_ev_executable.py:

- 0x5bdd4 loads STR#4004 base prices.
- 0x3eafc reads the default spread constant. Data-section 0x1a38 is the big-endian double 1.25; adjacent 0x1a30 and 0x1a28 are 1.1 and 1.5.
- 0x3eba4–0x3ec7c divides low bands, copies medium bands and multiplies high bands, using truncation; 0x3ec80 enforces a minimum of five for traded goods.
- 0x3ed10–0x3edac resets an event commodity to its base price before adding its event delta, rather than stacking that delta onto a preexisting band price.
- 0x672d0–0x67428 decodes source commodity-band bits.
- 0x453ac–0x453cc uses description 2900 and PICT 5200 for the secret shipyard display; the S/O/L key test sets its display flag at 0x4d638–0x4d670.
- 0x4ced4 compares the title key with ASCII x and branches to the haiku-display routine, which loads PICT 8011 at 0x4bd44.

The archive of Ambrosia's own tips corroborates the secret keys, asteroid cover and scanner interference:
https://escapevelocity.neocities.org/ev/archive/help-tips/

PEF decoding follows Apple's Mac OS Runtime Architectures, chapter 8:
https://dev.os9.ca/techpubs/mac/runtimehtml/RTArch-94.html

The temporary emulator reference could boot and expose the installed original game, but launching it was not reliable enough to record new playthrough or numerical comparison evidence. No manual-reference match is claimed from that attempt.

## Verification and remaining work

New focused suites: test_controls_strict.gd and test_environment_economy_secrets.gd. Existing shipyard, outfitter, map, port, freight, world activity, survival, controls and gameplay checks accompany the change. Nine automated campaign routes still pass 457 progression checks; these are not full manual original-game playthroughs.

Still unverified: exact original AI/scan/encounter/recovery timing, all service/hiring/resale formulas, two mission anomalies (224 PickupMode 5 and 228 ReturnStel -5), complete manual campaign balance, and remaining title modifier effects. Existing working interpretations of those mission fields are retained. No guessed mission-state or secret-ship statistics have been substituted to make the completion checklist appear finished.

Legacy add-ons remain excluded, rather than being treated as a blocker for the base remake.

## Release checks

Version 0.1.44 was exported successfully to `builds/Escape Velocity HD.app`; its bundle version was checked and the packaged executable completed an isolated fresh-pilot boot. The packaged resources passed all 1,298 environment/economy/secret checks. Source regressions passed controls/strict (16), base gameplay (115), missions (284), campaign routes (457), interaction history (32), live appeals (20), weapon audio (60), classic services (38), and fleet management (35), with zero failed checks. These automated checks do not replace the outstanding original-game comparisons above.

Further source lead, not yet applied: the executable helper at 0x4a914–0x4aa10 appears to discount eligible items by three percent per tech-level difference and round larger prices down. Existing-equipment resale at 0x42334 reads a 0.8 multiplier, with a different path for equipment purchased during the current visit. Confirm caller semantics and transaction accounting before replacing current service formulas.
