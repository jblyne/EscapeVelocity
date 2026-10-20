# Explosion hitch investigation — v0.1.11

Measured on this Mac (Apple M4 Pro, Godot 4.7.2, OpenGL Compatibility renderer) on September 20, 2026.

## Finding

The hitch was synchronous shader preparation at the first rendered explosion frame. Debris used freshly duplicated transparent/emissive materials. Once the last explosion expired, its generated shader variants lost their final material references. The next explosion paid their compilation cost again. Scene construction itself took only about 2.5 ms. The steady animation was already fast. The problem reproduced at every tested ship size; a larger model was not necessary to trigger it.

Controlled isolation with v0.1.10 confirmed the cause:

- Removing debris removed the recurring stall (leaving a one-time effect/lighting compilation).
- Keeping the first debris materials alive, without changing the artwork, reduced subsequent first frames from roughly 240 ms to 2–3 ms.
- Off-screen warmup also needed intact ships and a planet: the explosion's point light exercises their lighting shader variants too.

## Matched single-explosion measurements

Nine cases: three trials at model scales 24 (Defender), 31 (larger traffic), and 60 (stress case). Render size 1440×900; VSync disabled; fixed simulation increments; ordinary rendered frames measured through `frame_post_draw`. These are development-run measurements, not a guarantee for every display size or battle.

| Measurement | v0.1.10 | v0.1.11 |
| --- | ---: | ---: |
| First explosion, first rendered frame | 383.25 ms | 2.18 ms |
| Later explosions, median first frame | 240.24 ms | 2.19 ms |
| Worst first frame across nine cases | 383.25 ms | 2.56 ms |
| Median effect construction | 2.47 ms | 1.04 ms |

Raw matched results: `builds/explosion-profile-before.json`, `builds/explosion-profile-after.json`. Isolation runs are `explosion-profile-no-debris.json` and `explosion-profile-retained-materials.json` in `builds/`.

## Fix

Retain the finite debris material variants, share the identical particle plane mesh, and keep planet/atmosphere shader resources resident across system changes. During startup, render the unchanged effect with matching lighting and intact scene materials in an off-screen 32×32 viewport, then free that temporary scene. This moves compilation to startup. Each live explosion still owns independently animated material values. No debris, smoke, fire layers, timing, or shader artwork was removed; the explosion shader file is byte-for-byte identical to v0.1.10.

## Additional checks

A separate explicit-draw stress run avoids waiting on macOS's occluded-window drawing. Its frame timing method differs from the table above and should not be compared directly to it. Eight simultaneous explosions took 6.99 ms to construct and 9.73 ms for the first measured frame. The first explosion after a system reload took 2.86 ms. The warmup viewport was removed and created no live world explosions. Raw data: `builds/explosion-profile-after-controlled.json`.

The renderer returned zero for GPU timing, so these are wall-clock and CPU observations; zero was not interpreted as zero GPU work. The repeatable cache-retention experiment is the basis for identifying shader preparation as the cause.

Regression checks cover independent fading of simultaneous effects, pause, cleanup, player death, save preservation, scene changes, target previews, and arrival sound. Visual captures confirm the same appearance.

Run the current explicit-draw profiler with:

```sh
.tools/Godot.app/Contents/MacOS/Godot --path godot --script tests/profile_explosions.gd
```
