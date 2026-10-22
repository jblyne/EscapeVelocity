# Bar gambling — local build 0.1.193

Recovered from the locally unpacked Escape Velocity 1.0.5 executable:

- `0xa920`: gambling dialog 1015, three reels with six 64-pixel symbols.
- `0xaa..–0xab..`: 1,000- and 5,000-credit wager controls; insufficient credits block a bet.
- `0xaed0` / `0xb060`: count two or three matching symbols, multiply stake by doubles at data `0x1510` (1.3) and `0x1500` (3.0).
- `0xb434`: original symbol strip PICT 9001, recovered unchanged from EV Graphics.rsrc into assets/classic/9001.png.

The reconstructed screen uses those symbols, bets, and payouts with a sequential reel animation. Transactions settle and save before animation; this deliberately avoids losing pending winnings when navigating away. It does not reproduce the original hidden luck cheat or exact frame timing/sound resources.

Validation: five targeted Godot scripts pass (gambling, bar offers, recruitment, port mission triggers, port presentation), plus a native renderer screenshot check. The gambling regression covers pair/triple/no-match payouts, persisted settlement, duplicate-bet blocking, invalid bets, insufficient credits, and animation completion.
