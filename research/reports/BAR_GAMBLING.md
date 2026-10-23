# Bar gambling — local build 0.1.193

Recovered from the locally unpacked Escape Velocity 1.0.5 executable:

- `0xa920`: gambling dialog 1015, three reels with six 64-pixel symbols.
- `0xaa..–0xab..`: 1,000- and 5,000-credit wager controls; insufficient credits block a bet.
- `0xaed0` / `0xb060`: count two or three matching symbols, multiply stake by doubles at data `0x1510` (1.3) and `0x1500` (3.0).
- `0xb434`: original symbol strip PICT 9001, recovered unchanged from EV Graphics.rsrc into assets/classic/9001.png.

The reconstructed screen uses those symbols, bets, and payouts with a sequential reel animation. Transactions settle and save before animation; this deliberately avoids losing pending winnings when navigating away. It does not reproduce the original hidden luck cheat or exact frame timing/sound resources.

Validation: five targeted Godot scripts pass (gambling, bar offers, recruitment, port mission triggers, port presentation), plus a native renderer screenshot check. The gambling regression covers pair/triple/no-match payouts, persisted settlement, duplicate-bet blocking, invalid bets, insufficient credits, and animation completion.

## Original audio restored — 0.1.257

The executable loads `snd 460` (Slot Flip) and `snd 461` (Slot Lock) at 0xa994–0xa9b0. During a symbol-boundary crossing, 0xac44–0xac6c plays the flip only if that sample is not already playing. The reel's final alignment plays Slot Lock at 0xadc0–0xadd4.

Pair wins use the first explosion-array entry at 0xaf0c–0xaf20; triples use entry three at 0xb09c–0xb0b0. The array is filled with `snd 300..303` at 0x5b394–0x5b3b8. Thus the original payout cues are HeavyExplosion (300) for pairs and ShipExplodes (303) for triples, rather than a separate authored casino jingle.

`tools/extract_gambling_audio.py` preserves the unsigned 8-bit mono PCM from EV Sounds.rsrc, at the original 11127 Hz rounded sample rate. Flip: 242 samples; lock: 1600 samples. Payout players reuse the already recovered 300 and 303 streams, separate from combat audio so stopping casino playback cannot interrupt explosions. The existing sequential reel animation triggers flips on changing symbols, locks each reel once, and plays a payout only after the final stop. All slot playback stops on leaving or starting a new wager, and respects mute and master volume. `tools/test_menu_audio.py` verifies the source PCM byte-for-byte; the native gambling-audio regression covers the event wiring and cleanup.
