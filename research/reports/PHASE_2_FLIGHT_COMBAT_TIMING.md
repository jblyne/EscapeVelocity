# Phase 2 — Flight and combat timing (0.1.159)

21 October 2026. Base-game timing, excluding add-ons. Requested Maverick handling, weapons, audio, wing sweep and current default selected-weapon controls are retained.

## Reference and reproducibility

The local checksum-identified Escape Velocity 1.0.5 PowerPC executable is the primary numeric reference. Run `python3 tools/extract_reference_timing.py` to reproduce the instruction/constant checks and `research/decoded/reference-timing.json`. This reads the original executable without modifying it and records its code-section SHA-256. No external engine implementation or guessed replacement ship data is used.

The import relocation's initial 307-word import run binds TOC word 119 to TickCount. Stub 0x7762c dispatches it. The main loop records this clock at 0x15964, performs an update, and waits at 0x15b30–0x15b40 until the next tick. This establishes a nominal maximum of 60 updates/second, rather than a guarantee that every vintage Mac sustains 60. The remake uses a deterministic 60 Hz reference clock; emulation/host slowdowns are not copied.

A fresh disposable pilot was also launched in Infinite Mac's bundled original. A held 750 ms right-turn changed the shuttle from vertical to the opposite vertical orientation; another 375 ms made it horizontal. These coarse, sprite-quantized observations support the recovered 240 degrees/second shuttle rate. Input delivery and capture overhead prevent claiming sub-frame precision. Acceleration/recovery numbers below come from executable instructions, not fabricated wall-clock observations.

## Recovered rules and implementation

| Quantity | Original evidence | Implementation at normal game speed |
|---|---|---|
| Acceleration | 0x24718–0x24758 loads Accel/10000; 0x62400–0x62544 applies normal factor 2 | `Accel × 1.2` world units/second² |
| Cruise speed | 0x2475c–0x2479c loads Speed/100; 0x62548–0x62628 applies player factor 1.75 | Player `Speed × 1.75`; ordinary NPC catalog speed unchanged |
| Turning | 0x622b0–0x623e4 uses maneuver as degrees per update; 0x36334–0x36448 applies it | `Maneuver × 60` degrees/second |
| Engine outfits | 0x62444–0x624c4 and 0x6258c–0x6260c add ModType 7/8 values before multipliers | Add 150 Accel / 150 Speed; RCS adds 1 Maneuver |
| Weapon reload | Source Reload counter and 60 Hz update clock | Source Reload/60 seconds, retained fractional countdown while held |
| Projectile lifetime | 0x1ddc0–0x1de18 initializes Count/game-speed counter; 0x15f14–0x15f3c decrements | Source Count/60 seconds; final movement clipped to remaining life |
| Recovery | 0x36544–0x365ac and 0x18790–0x18804 use global-counter modulo recharge, then truncate signed integrity + 1% maximum shields | Shared reference-tick pulses, armor before shields, truncation toward zero after addition |
| Counter wrap | 0x15a34–0x15a50 resets after 1024 | Shared phase wraps every 1025 reference ticks |

One original coordinate is represented by 5/3 remake world units. This is an explicit coordinate-scale choice, not an original constant: it preserves the existing raw weapon Speed values as world units/second (`Speed/100 × 60 × 5/3`). Ship acceleration, cruise speed and projectile speed therefore use the same distance/time scale.

Example: the stock player shuttle cruises at 481.25 world units/second, accelerates at 522 units/second² and completes a full turn in 1.5 seconds. These replace the provisional 275 cruise, 304.5 acceleration and roughly 2.42-second turn. The source player/NPC speed difference is intentional. Ship speed/acceleration upgrades are additive rather than a universal 50 percent bonus.

Recovery rounding is significant: with a 180-shield ship, signed integrity -10 becomes `int(-10 + 1.8) = -8` (two armor repaired), while +10 becomes +11 (one shield repaired). The former implementation truncated the increment first and smoothed it continuously. All contacts now share the same phase; damage does not restart recovery. Disabled NPCs and cloaked players still cannot recover, and menus freeze the clock.

## Other corrections and preserved behavior

- Jump arrival now uses effective player flight fields, including installed upgrades. It previously used raw catalog speed even when ordinary flight used an upgraded speed.
- Selected and classic primary firing retain fractional reload overshoot while held, with bounded catch-up. Releasing the trigger discards overdue firing debt. Selecting Sidewinders still fires Sidewinders; classic firing remains optional.
- Projectile collision sweeps stop at the actual lifetime endpoint, preventing a near-expired round from hitting beyond its range on a long update.
- Hyperspace braking, auto landing, autopilot, refueling rendezvous and departures use the same acceleration helper. Maverick's custom flag retains its prior .7 acceleration and .65 turn conversions and prior upgrade behavior. Its afterburner multipliers remain unchanged.
- The existing source Count/Reload conversion is now supported by the executable clock investigation. No unrelated missile-guidance or encounter-AI algorithms were substituted.

## Verification and boundaries

`test_phase2_timing.gd` checks every original hull's conversion and cruise limit, source projectile lifetimes, engine upgrades, effective arrival speed, recovery rounding/phase/wrap, selected and classic cadence, pause behavior and range endpoints at 30/60/120/144 updates per second. Existing flight, jump audio/departure, chain jump, autopilot, selected firing, Maverick, weapons, fleet and campaign regressions accompany the build.

The modern engine retains smooth heading/interpolated integration and a vector cruise cap. The original uses integer-degree updates and component-wise engine limits. At non-default game speeds, original integer truncation of maneuver/reload/recovery intervals can differ from the remake's continuous time scaling. Weapon guidance, inherited launch velocity, special NPC speed modifiers, pursuit/retreat/encounter decisions, and fighter/carrier handling remain their existing implementations and belong to the subsequent fidelity passes. This report establishes verified numeric timing rules, not complete frame-for-frame original-engine equivalence or a full manual campaign playthrough.

Final validation: 2,347 source checks passed across 22 suites, including 335 focused timing checks and nine campaign routes. The universal 0.1.159 Mac bundle exported successfully, passed strict signature verification, and launched with no script/preload errors. `git diff --check` passed. The update is local; no GitHub push or release was made.

Additional packaged `--script` regression invocations produced no test summary and did not exit; those isolated processes were stopped. They are not counted as passing tests. Source suites and the separate native standalone launch check passed; full standalone gameplay acceptance remains Phase 6.
