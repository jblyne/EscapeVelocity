# Original hyperspace audio

Local EV 1.0.5 executable loads snd 128 (Warp Up) at 0x5b304 and snd 130 (Warp Out) at 0x5b318. Warp Up playback at 0x35810–0x35828 follows velocity checks at 0x35744–0x35790 and the preparation state change at 0x357a8. It does not belong to the initial J input or repositioning. Warp Out is dispatched through 0x30588–0x305c0; its completion flag gates the system transition at 0x35ac8.

The remake plays native-pitch Warp Up at the stopped/aligned spooling transition, keeps it running through acceleration, and plays original Warp Out on system entry. Exact original engine movement duration and the pre-transition Warp Out callback timing are not reproduced; these remain tied to the remake flight phases. Synthesized jump and generated thunderclap are no longer used by player hyperspace. PCM is checked byte-for-byte by tools/test_menu_audio.py.

0.1.79: accepted jump input uses original interface slot 2 / snd 152, visible at 0x328bc–0x328d0. Spool plus burn duration derives from the native Warp Up stream length, with transition quantized to one physics tick.
