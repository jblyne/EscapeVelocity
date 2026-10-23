# Original modal-window alert

EV 1.0.5 imports Macintosh SysBeep at import 283 (TOC -0x7b94), stub 0x76eac. The title event handler calls FindWindow at 0x4c924 (stub 0x780c4) and issues SysBeep(1) for the desktop/outside-window case at 0x4c95c–0x4c960. Original dialogs also use Macintosh ModalDialog (stub 0x77014), whose default handling rejects clicks outside the front modal dialog. This alert comes from the Mac system, not EV Sounds snd 150–154.

The reference System 7.5.3 System resource fork contains snd 1, named Simple Beep. It specifies a square-wave synthesizer with timbre 90, MIDI note 69, and twelve 40-half-millisecond waits with the original stepped amplitudes. snth 4097 contains the waveform generation routine at 0x2d8–0x38e, its quarter-sine table at 0x3b6, and the A4 phase-step constant 0x50fba. The renderer ports its integer wavetable generation and preserves the command timing at nominal 22255 Hz. This is a cached rendering of the original synthesizer commands, not a microphone recording.

Sources:
- User’s extracted Escape Velocity 1.0.5 executable.
- https://github.com/mihaip/infinite-mac/blob/main/Images/System%207.5.3%20HD.dsk (read-only reference image; Git blob 5a6210ca27a805643f9ea6e7bc70550247307029).
- Apple Inside Macintosh: Sound, Sound Manager command definitions and Simple Beep listing: https://www.resourceforks.com/thinkc/Inside%20Mac%20-%20Sound%20Mgr/9.html

Only the alert’s small source command list and sine table are retained in godot/data/classic_modal_alert.json, with source resource hashes. tools/extract_modal_alert.py reproduces godot/audio/modal_alert.wav.
