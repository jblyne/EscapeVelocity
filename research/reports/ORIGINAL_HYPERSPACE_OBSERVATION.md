# Original Escape Velocity: two observed hyperspace jumps

Observed September 20, 2026 in Infinite Mac, Mac OS 7.6:
https://infinitemac.org/1997/Mac%20OS%207.6

## Session and method

- Successfully flew **Levo → Rigel → Levo**, using the bundled original Escape Velocity and a separate new Shuttlecraft pilot in Chrome. The existing in-app emulator was not intentionally reset. At the end of the pass its tab was no longer available through the browser tools (the cause is unconfirmed); the working Chrome test session was retained, paused in the Levo map after the return jump.
- Opened Preferences → Game Speed and visually confirmed **100%**. No 2× indicator was visible during either recorded jump. The bundled application's exact patch version remains unconfirmed; do not assume its executable matches the separately recovered 1.0.5 data.
- Browser key taps were often missed by the game's polled flight controls, even though Finder/dialog shortcuts worked. Bounded bursts of `pressKey` calls worked: 250/800 Up taps for outward thrust; 120 J taps over approximately 0.45 seconds for a jump request; about 100 M taps to pause in the map. `typeText` is not an adequate substitute for physical keys in this emulator.
- Recorded timestamped browser screenshots into the computer-use session memory, at roughly 30 screenshots/second. First successful jump: 674 frames over 22 seconds, starting after the initial turn had begun. Return jump: 716 frames over 23 seconds, including a frame before J. No thrust, steering, or braking input was applied during either capture after J.
- Captures used an 800×600 crop of the emulated display (browser rectangle x=295, y=100). The flight area is approximately 656×600, with the player's ship centered near (328,300). Coordinates below refer to this crop, not the browser window or the Godot camera.
- Images were inspected in the task conversation. Raw image sequences currently exist only in the live computer-use session, not as a saved video or image archive. This document preserves the timestamp/coordinate observations.

## Direct observations

1. **Departure takes control of heading and motion.** On the return trip the shuttle initially faced/drifted southwest, turned around toward northeast, settled into alignment, then accelerated before the system changed. There is a noticeable aligned interval before the final acceleration; it is not simply an immediate constant-speed departure.
2. **The return trip took approximately 9–10 wall-clock seconds from the J request to arrival.** At capture time 9.313 s the old navigation/fuel state was still visible; at 9.499 s the entry message and decreased fuel were visible. Initial heading and velocity affect the preliminary maneuver. Do not turn this single measured total into a universal jump duration or derive exact phase durations from it.
3. **Arrival preserves substantial forward motion.** In Rigel the shuttle faced/traveled southwest; on returning to Levo it faced/traveled northeast. The planet moved across the ship-centered view at a nearly constant rate without any input. The ship neither stopped at arrival nor automatically braked near the planet.
4. **The planet starts off-screen.** It is visible on the radar before reaching the main view. Both arrivals were from the side corresponding to the incoming connection, approaching the system's central planet. The trajectory passed near the planet rather than placing the ship at its surface.
5. **No input means flying past the planet.** Closest approach occurred roughly 4–5 seconds after entry in both captures. After 20+ seconds the ship was already far beyond it.
6. **System transition changes the navigation state, fuel, and date.** With a single-hop route, the sidebar returned to `Nav System Off`. Fuel fell from a full tank to approximately three quarters at Rigel, then approximately half at Levo. Entry messages showed Sept. 21st and Sept. 22nd, 2276, following the initial Sept. 20th date. Each of these adjacent jumps advanced the date one day; this is not evidence for every ship/route.
7. **The transition goes directly into the new starfield.** No prolonged tunnel sequence was observed. The original retains small point-like stars; the modern prototype's radial streak effect is an added presentation choice.

## Approximate speed and distance

These are **screen measurements and extrapolations**, not recovered engine constants or verified kilometers. Planet centers were estimated visually to within a few pixels. Timing is host wall-clock time at the emulator's 100% game-speed setting, and may be affected by emulation and capture overhead.

| Capture | Timestamp (s) | Planet center x | Planet center y |
| --- | ---: | ---: | ---: |
| Rigel / New Britain | 6.5005 | 79 | 559 |
| Rigel / New Britain | 7.4835 | 262 | 340 |
| Rigel / New Britain | 8.4835 | 447 | 121 |
| Levo return | 13.0035 | 576 | 40 |
| Levo return | 14.0125 | 386 | 264 |
| Levo return | 15.0000 | 205 | 482 |

The stationary planet's movement is opposite the ship's velocity. Endpoint displacement divided by elapsed time gives approximately **289 px/s into Rigel** and **289 px/s into Levo**. Use a conservative **280–300 screen px/s** range. The three samples per trip are consistent with a steady coast, rather than a rapid post-arrival slowdown.

The Rigel system change occurred between approximately 3.006 and 3.092 s of its capture; the Levo change between 9.313 and 9.499 s. Extrapolating each planet's position back to those entry windows gives roughly **1,300–1,500 screen pixels from the planet's center**, or a little over **two heights of this 600-pixel flight view**. This is an estimate, not proof that the engine always uses a fixed radius. Two central, single-world systems are insufficient to establish the rule for offset planets, stations, or multi-world systems.

For reproducibility, with a planet sample p(t), player center c=(328,300), and fitted planet screen velocity v:

`entry offset = p(t) - c - v * (t - entry time)`

`entry distance = length(entry offset)`

The recovered 1.0.5 Shuttlecraft record separately contains `Speed=275`. That data value is compatible in scale with this observation, but its exact conversion to pixels, game ticks, or the HUD units in our Godot build is still unverified.

## Implications for the Godot recreation

Version 0.1.4 resets velocity to zero in `load_system()` and places a jumping pilot 330 world units from the primary world. **That arrival behavior contradicts both observed original jumps.**

The next fidelity change should:

- Spawn on the incoming-route side, outside the immediate planetary view.
- Arrive facing and moving along the incoming warp line toward the system, with substantial steady cruise velocity.
- Preserve coasting after entry; leave approach braking to the pilot.
- Match the observed time-to-planet and on-screen distance after accounting for the different Godot camera scale and planet sizes. Do not paste screen pixels directly into world-unit constants without that mapping.
- Compare the aligned spool interval and final acceleration separately; the current 2.4-second acceleration phase has not been established as an original timing constant.
- Consider resetting single-hop navigation after arrival, with a queued route handled separately when implemented.

The observation pass itself changed documentation only. The subsequent implementation is recorded below.

## Godot 0.1.5 implementation

- Departure now includes a 4.5-second aligned spool with engines off, followed by the existing 2.4-second acceleration. These are tuning choices, not measured original phase constants. With the shuttle at full southwest cruise and a northeast destination, the complete remake maneuver takes **9.1 seconds** at 60 Hz. Other initial speeds/headings change the maneuver time.
- A completed jump enters along the incoming connection heading at the ship’s cruise speed (**275 world units/second** for the shuttle). A central primary receives a **4.8-second / 1,320-world-unit** approach, with a small sideways offset of 35% of its radius. The pilot keeps coasting without engine input; no arrival braking is applied.
- The existing 900-world-unit camera height and manual zoom range remain. The world-unit approach matches time to the planet and keeps it initially off-screen at default zoom; its screen-height ratio is not identical to the original 600-pixel view. This deliberately avoids treating the observed pixels as proven engine units.
- The first world is the approach focus, including offset primaries. Empty systems use the origin. For multiple worlds, the approach is extended upstream past every gravity exclusion circle intersecting the approach line; it may therefore take longer to reach the primary. This extension is a remake rule, pending original-game observations in those systems.
- The local scanner now spans 2,000 world units in radius, keeping the central primary visible on radar when arriving. Engine exhaust is off during the arrival coast.
- Single-hop navigation clears on arrival. The HUD and map handle this state; N or a map selection sets the next route. Fuel is charged once, at transition; cancellation, gravity checks, and pause remain in force.
- Validated with **101 passing Godot gameplay checks**, including actual Levo → Rigel → Levo scene transitions, steady 4.8-second coasting, 30/60/120 Hz spool behavior, and safe entry for every connected catalog approach. Screenshot captures cover departure, arrival, the subsequent approach, and the map with navigation cleared.


## Godot 0.1.6 playtest adjustment

The user reported that 0.1.5 spent too long spooling and too little time accelerating, with insufficient departure speed. The normal-flight speed cap was still applying during the entire departure burn.

- Aligned spool: **4.5 → 0.6 seconds**.
- Acceleration: **2.4 → 4.8 seconds**, continuously building to **6× cruise speed** (1,650 world units/second for the shuttle), covering about 3,960 world units during the burn.
- The jump sound stretches over the full burn, and the HUD identifies departure speed as hyper speed.
- Canceling retains momentum above cruise. Main-engine thrust can brake it progressively; ordinary flight cannot accelerate beyond its cruise limit. Arrival still resets to normal cruise on the unchanged 4.8-second approach.
- These settings prioritize the user’s playtest feedback; they are not claimed original phase timings. The same full-speed turnaround test now takes **7.583 seconds**.
- **115 gameplay checks pass**, including departure speed/displacement at 30/60/120 Hz, pause and cancellation during boosted travel, progressive braking, and all existing arrival checks.
