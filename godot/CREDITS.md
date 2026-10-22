# Credits

Original Escape Velocity game and scenario: Matt Burch / Ambrosia Software, 1996. The prototype imports resource definitions from the preserved Escape Velocity 1.0.5 archive supplied as the project reference.

Reconstruction code, procedural ship and planet visuals, interface, and synthesized prototype sounds: created for this Escape Velocity HD project, 2026. These are early prototype assets, not finished replacement artwork.

Original menu artwork and animation, forklift reference sprites, forklift engine sound, ship/heavy explosion recordings, and cloaking on/off recordings: Matt Burch / Ambrosia Software, recovered from the supplied Escape Velocity 1.0.5 resource files. The forklift 3D model and cloak fade are reconstructed for this project.

This game uses Godot Engine, available under the MIT license. Godot copyright and license information: https://godotengine.org/license/

Godot third-party notices: https://github.com/godotengine/godot/blob/4.7.2-stable/COPYRIGHT.txt

Combat panic cries: AI-generated performances created through the user’s ElevenLabs account using Eleven v4. Active commander voices: Harry, George, Callum, and Charlie. Human death cries: Adam, Callum, and Harry. Alien cries: Adam. Earlier Roger and Jessica warning takes are archived. Original downloads and prompts are preserved in `research/audio/elevenlabs/manifest.json`. `tools/generate_panic_audio.py` converts these saved recordings without resynthesizing them. These are not original-game samples.

Crew scream mixes: layered versions of the saved ElevenLabs cries, created by `tools/mix_crew_screams.py` with staggered starts, varied pitches, normalized levels, and a short fade.

Burning-wreck final words: additional ElevenLabs Harry and Callum performances, layered with saved crew screams by `tools/mix_wreck_audio.py`.

### Steel reconstruction artwork

The steel-panel and reclaimed-soil material maps were generated with the built-in image generation tool for this project. Exact prompts are retained in `assets/reconstruction/art_direction.json`. The 107 unique rebuilt worlds, staged orbital pictures and landing scenes are deterministic 3D renders authored in `scripts/rebuilt_world.gd` and `tests/render_reconstruction_art.gd`, rather than recovered original-game art.

HD main-menu console remaster: generated with the built-in image_gen tool from the original menu, preserving its design. Prompt and provenance: assets/menu/art_direction.json. Original mechanical animation, live labels and interactive controls are rendered in Godot.

HD startup artwork: faithful remasters of the original Ambrosia Software logo and Escape Velocity loading illustration, generated with the built-in image_gen tool. Original artwork and trademarks belong to their respective creators. Prompts and references: assets/startup/art_direction.json.
