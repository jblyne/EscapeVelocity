# Restored interface sounds

Original local EV Sounds.rsrc provides Beep1–Beep5 (150–154) and Airlock (390).
`tools/extract_interface_audio.py` preserves their uncompressed mono 8-bit PCM,
with integer sample rates rounded from the original Sound Manager fixed point.
`tools/test_menu_audio.py` now checks their samples alongside menu/music audio.

Source executable reference: 0x5b334–0x5b358 fills the interface sound array from
resources 150–154. Gameplay input 0x323d8/0x32758 uses array slot 0;
0x32494/0x327dc uses slot 2. Refusal paths 0x32a80/0x33248 use slot 3.
Successful transfer handling 0x1d514 uses slot 4. Boarding code 0x346e4 loads 390.

Remake event wiring:
- Tab ship targeting / clearing: Beep1.
- World and navigation selection, shipyard/outfitter/mission row selection: Beep3.
- Landing completion: Beep2, replacing the old generated two-tone land.wav cue.
- Landing clearance, equipment buy/sell and mission acceptance: Beep5.
- Refused/unsafe landing and blocked outfit transactions: Beep4.
- Successful ship boarding: Airlock.
- Generic modal buttons use the already-restored original Click recording.

Clearance is an authored two-step remake interaction; its confirmation cue and
the modern service selection placements are adaptations of the original sound
vocabulary, not a claim of complete event-for-event original-engine parity.
Initialization, redraws, and unchanged world reselection produce no selection
sound. Existing mute handling applies; UI players use bounded polyphony.
