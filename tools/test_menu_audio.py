"""Verify the delivered menu WAVs preserve the original game's sample data."""
import unittest
import wave
from extract_menu_audio import ROOT, SOURCES
from extract_interface_audio import SOUNDS
from extract_gambling_audio import SOUNDS as SLOT_SOUNDS
SOURCES={fork:dict(names) for fork,names in SOURCES.items()}
SOURCES["EV Sounds.rsrc"].update(SOUNDS)
SOURCES["EV Sounds.rsrc"].update(SLOT_SOUNDS)
SOURCES["EV Sounds.rsrc"].update({300:"heavy_explosion",303:"explosion"})
from extract_special_effects import pcm_sound
from inspect_ev import read_resources

class MenuAudioTest(unittest.TestCase):
    def test_original_samples(self):
        for fork,names in SOURCES.items():
            source=next((ROOT/'research/extracted').rglob(fork))
            resources={r['id']:r for r in read_resources(source.read_bytes()) if r['type']=='snd '}
            for resource_id,name in names.items():
                with self.subTest(recording=name):
                    pcm,rate=pcm_sound(resources[resource_id]['data'])
                    with wave.open(str(ROOT/'godot/audio'/f'{name}.wav'),'rb') as audio:
                        self.assertEqual(audio.getnchannels(),1)
                        self.assertEqual(audio.getsampwidth(),1)
                        self.assertEqual(audio.getframerate(),rate)
                        self.assertEqual(audio.readframes(audio.getnframes()),pcm)

if __name__=='__main__':
    unittest.main()
