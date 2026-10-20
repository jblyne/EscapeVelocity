# Auxiliary mission arrivals — 0.1.47

Auxiliary mission ships now wait for a separate randomized encounter counter instead of appearing immediately alongside the main objectives. Main encounter behavior and the existing three-second delayed-main-wave tuning are unchanged.

## Original executable evidence

Reference: the extracted Escape Velocity 1.0.5 executable, decoded with `tools/unpack_ev_executable.py` and `tools/disassemble_ev_reference.py`. Addresses below are PPC code-section offsets in `/tmp/ev-ppc.txt`.

- `0x541e0–0x54200` initializes the mission runtime auxiliary counter at offset `0x5a` with `70 + Random(70)`.
- The random helper at `0x65450–0x65460` multiplies the requested range by an unsigned 16-bit sample and shifts right 16 bits: the counter range is 70–139 inclusive.
- `0x1b754–0x1b76c` skips auxiliary spawning while that counter is positive. Main encounter processing continues separately at `0x1bb1c`.
- `0x1c08c–0x1c0c0` decrements the counter once per encounter update. Equivalent resets occur in encounter initialization paths including `0x281c4–0x281e4`.

## Implementation and limits

The remake converts the counter at a nominal 60 encounter updates per second, giving a 1.17–2.32 second initial window. **The original updater's wall-clock cadence has not been measured.** The range and separation are source-backed; this seconds conversion is an explicit integration assumption.

Counters advance with flight simulation time, retain fractional elapsed time, reset on system load and landing traffic refresh, and are released when a contract finishes. Reload starts a new encounter window while retaining each finite auxiliary's destroyed state. Existing infinite-auxiliary replenishment behavior is unchanged; its precise source timing remains open.

## Verification

Focused arrival checks cover separate main/auxiliary timing, random bounds, fractional expiration, duplicate prevention, finite losses across save/reload, encounter resets, and contract cleanup. Campaign routes, mission progression, original encounter records, landing traffic, and cargo scan regressions also run for this release. This does not complete manual original campaign comparison or exact AI timing parity. Add-ons remain excluded.

Results: arrivals 20/20, campaign routes 457/457, mission progression 284/284, original encounters 174/174, launch traffic 12/12, cargo scans 29/29: **976 checks, zero failures**. The exported pack passes the same 20 arrival checks; the 0.1.47 app boots and exits successfully with a disposable fresh save. Export completed despite a sandbox-blocked editor-preference save. Headless runs also report the existing macOS certificate and shutdown resource warnings; no script/parse failures were found.
