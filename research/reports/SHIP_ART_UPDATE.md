# Ship detail pass — v0.1.17

All 27 original ship records now use beveled procedural hulls and chamfered panels. The source silhouettes, sprite-size proportions, faction assignments, flight parameters, hit radii, and weapon behavior remain unchanged. These details are newly authored remake artwork.

The shuttle has a framed canopy, armor hatch and paired cooling vents. Fighters gain layered wings and gun mounts. Freighters have reinforced cargo modules and hatches. Capital ships have layered decks, turrets, sensors and engine cooling grilles. Passenger ships retain rows of windows; alien ships use segmented red armor and luminous seams. Engine nacelles have cylindrical shrouds, collars, inset exhausts and cooling fins. The target panel copies the same detailed model used in flight.

`ship_detail.gd` generates the geometry and combines static parts by material and hull section, retaining separate animated exhaust. Indexed primitive meshes and unindexed hulls are expanded into the same triangle format before merging. Section origins are recentered for local debris rotation. Packed models share the resulting mesh and material resources across identical ships.

## Validation

All 369 Godot checks pass, including two new batching regression checks. Visual review covers the complete roster, six enlarged models, normal flight, the selected-ship preview, and a cruiser explosion.

An initial profiling pass found a 105–128 ms first-explosion hitch: luminous gun sights used different culling from the shuttle's exhaust and introduced a debris shader variant that startup had not warmed. Consistent culling across ship materials lets the existing warmup cover both lit and unlit debris variants.

Final spot check on this Mac (Apple M4 Pro, Godot 4.7.2, OpenGL Compatibility, 1440 × 900, VSync disabled):

- 27-ship roster: explicit-draw median **1.445 ms**, p95 **1.716 ms** across 90 samples.
- Cruiser explosion: creation **1.002 ms**; creation plus first explicit draw **4.154 ms**.
- Maximum per ship: **16 mesh nodes including exhaust**, **5,216 triangles**.

These are isolated wall-clock checks, not GPU timings or a prolonged combat frame-rate guarantee. Existing battle checks also exercise carriers, fighter wings, projectiles and simultaneous explosions.

Captures: `builds/ships-0117-showcase.png`, `builds/ships-0117-roster.png`, `builds/ship-detail-flight.png`, `builds/ship-detail-explosion.png`. Raw timing log: `builds/ship-detail-final.log`.

Reproduce with:

```sh
.tools/Godot.app/Contents/MacOS/Godot --path godot --script tests/capture_ship_detail.gd
```
