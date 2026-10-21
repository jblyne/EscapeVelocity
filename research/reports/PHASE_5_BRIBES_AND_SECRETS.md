# Phase 5 — Bribes and secrets (0.1.174)

Base EV only; preserve F-14/Maverick additions and default selected-weapon controls.

## Recovered evidence

Read-only Escape Velocity 1.0.5 PowerPC code, SHA-256 `e30f18040f31f810ed35cbfffb803824d9f580ab9405314cf5d819dcf4d5bf01`. `tools/extract_reference_bribes.py` checks instruction bytes and extracts doubles into `research/decoded/reference-bribes.json`. Existing local disassembly `/tmp/ev-ppc.txt` supplied the surrounding branch context.

- Ship quote, 0xefc8–0xf2a8: mood `(80 + random(41)) * .01`; a 1/5 check subtracts .5, otherwise a separate 1/5 check adds .5. Normal base is `3000 + random(max(1, trunc(wallet * .0000005))) * 1000`. Government flag 0x8000 substitutes base 10000 and wallet multiplier .0001. Multiply by mood, cap against `.333 * wallet`, truncate to thousands, clamp to 1000–900000.
- Landing quote, 0x109ec–0x10bbc: `3000 + random(max(1, trunc(wallet * .000001))) * 1000`; flag 0x8000 multiplies by 1.5. Apply the same wallet ceiling, thousands rounding and bounds. Tech level and ship purchase price are not inputs to these quoted formulas.
- Landing willingness, 0x10d64–0x10e5c: the daily random result must be greater than 30; independent government -1 qualifies directly, otherwise government Flags must contain 0x4000. The initial price can still be unaffordable: the original 1000 minimum is applied after the wallet ceiling.
- Generic negotiation, 0x12ad4–0x12ca8: random(100) <= 50 accepts bargaining. Paying multiplier .75, followed by truncation to hundreds. The receiving-payment multiplier 1.33 is extracted for evidence, not applied to unrelated features. Failed landing bargaining clears willingness and adds 1000 to the undiscounted request (0x111dc–0x11210); the ship payment caller also increases a rejected request by 1000 (0x10204–0x10214).
- The hostile ship dispatch at 0xf930–0xfa6c rejects an owned/follower slot and routes combat AI roles >=3 through the payment dialog; lower roles refuse. Existing disabled/friendly/alien and invulnerable/Hector gates are retained in the modern explicit Offer Bribe interface. This is not a complete port of every original named-character/assistance state.
- GetKeys reader 0x606e0–0x60750 reads big-endian 16-bit words. To interpret its tested indices as Macintosh virtual key codes, XOR with 8. Thus About test 0x32 is Option (0x3a), 0x3f is Command (0x37), and the additional tests 0xb/0x33 are F/Control. About dispatch 0x4bb2c–0x4bc54 selects STR#20002 for Option and STR#20003 for Command; normal credits are STR#20001. Original title-key X haikus remain.
- Satellite display 0x4539c–0x453cc uses description 2900 and PICT 5200. S/O/L key tests remain at 0x4d5fc–0x4d670. The recovered display is retained; this evidence does not establish a separate flyable hull with verified statistics.

## Delivered behavior

`bribery.gd` centralizes source quote arithmetic and negotiation rounding. Ship and planetary bribes now use wallet/government inputs and source limits. Ship hails offer a classic grey Negotiate button, disable further negotiation after an attempt, charge the exact displayed quote once, and preserve per-contact ceasefires and government standing. Failed landing bargaining makes the day's officer refuse; a later day gets a fresh opportunity. Officials and cached quotes are isolated between pilots. Landing clearance remains temporary and cannot bypass an active defense siege.

Option-About opens the original parody credits. Command-About opens the original additional credits. The parody forklift chord accepts Option+Control+Command+F while the recovered MCB line is visible; the previous extra-Shift combination remains accepted. Typing or navigating a pilot-creation/dialog screen cannot trigger title secrets. Existing Option-logo, haiku, forklift unlock, and persistent Satellite preview conveniences remain. Shipyard S/O/L ignores repeated key events, and the Satellite view never silently replaces the pilot's hull or charges a ship purchase.

## Explicit comparison boundaries

The random generator is modern. Quotes are held stable per contact or port/day to prevent repeated hails from rerolling prices; the original quote setup can be re-entered. The source random helper takes signed 16-bit bounds; overflow quirks for huge modern credit balances are intentionally not emulated. The recreated title/credits compositor and visible-line forklift timing are not a frame-for-frame port. The Shift-About preference/register/debug branch is not implemented without mapping its complete side effects. Satellite remains a verified illustration/text secret, not guessed flight statistics. Complete manual comparison and standalone release acceptance belong to Phase 6.

## Verification

`test_phase5_bribes_secrets.gd` covers wallet ceilings, source rounding/bounds, surcharge, willingness boundary/government flags, actual ship negotiation controls, exact charges and no double payment, refusal, stable quotes and pilot isolation, title modifiers/dialog safety, and unchanged hull/credits in the Satellite view. Native visual review verifies the bribe screen's controls and quoted amount fit. Existing ship interactions, original gameplay, landing bribes, environment/economy/secrets, controls/strict, interaction history and shipyard regressions pass. The read-only extraction tool validates its source instructions and writes the evidence fixture. All 2,199 checks passed. The local signed Mac app is rebuilt, its strict signature verifies, and an isolated native startup completes successfully; no GitHub publication is part of this phase.
