# Named-character encounter implementation

The full 220-record original roster is supported. Normal characters enter through rare ambient arrivals, subject to source location/government and mission-bit restrictions. Hector keeps his existing dedicated behavior. The special -32000 bounty-hunter record now has a wanted-pilot trigger. A character picker in Cheats provides direct access while respecting eligibility, duplicate prevention and system capacity.

Implemented from the local përs records:

- Original names, hulls, governments, ship roles, shield modifiers, credits, weapon additions/removals and ammunition.
- Aggression-dependent acquisition distance, shield-percentage retreat, afterburner escape, and escape pods. Surviving pods allow a later reappearance; destroying a pod permanently removes its owner. Capture also removes the original character from future spawning.
- Saved grudges and permanent removals; duplicate prevention also covers live pods and active named mission escorts.
- Original communication and radio text, token expansion, friendly/grudge conditions, attack-start and disabled-ship calls, once-per-encounter broadcasts, cooldowns, mission-availability suppression, and news-sharing captains.
- Hail/boarding mission offers with original ship-class exclusions, stable offers, capacity checks, deactivation and departure flags. Boarding the false distress calls automatically launches the original ambushes.
- Named courier escorts retain their original identity, hull and loadout across travel and saves. Capturing an escort cannot resurrect a duplicate on the next jump.
- Independent systems now retain local legal records, so ship-linked availability can evaluate the player's standing in the actual encounter system, including the derelict Kestrel-parts story. State is backward-compatible and validated.

All seven linked missions (195, 196, 197, 198, 199, 201, 202) are exercised by integration tests. Both ambushes activate through real boarding. Passenger, freight and escort contracts complete through travel and landing. Mission 201 grants original bit 73 for the alternate Kestrel.

## Validation

- test_person_roster.gd: 956 checks. Instantiates every record in an eligible context, verifies identity/hull, and exercises combat, retreat, pods, radio conditions, mission-class/cargo restrictions, linked missions, legal state and persistence.
- Regression suites: original encounters 174; faction campaigns 151; world activity 38; communications/boarding 73; Hector 15; cheats 103.
- Rendered Matt Burch dialogue and merchant-courier offer inspected in builds/person-matt-hail.png and builds/person-courier-offer.png.

## Reconstruction boundaries

The original resource files are the primary source. The compatible field meanings were cross-checked against [Matt Burch's Resource Bible](https://andrews05.github.io/evstuff/guides/evnbible.html), with the existing SpacePort source used previously to check legacy field compatibility. This is not a byte-for-byte port of the original executable.

Aggression radii (400–1600 game units), afterburner acceleration/speed, retreat exit distance/time, radio cadence, the bounty threshold (-100 with a government), and the per-system independent-record model are remake tuning. Combined friendly/grudge flags are treated as alternative conditions, matching their coexistence on the original Rebel records. The existing Hector exception and two-live-person ambient cap are retained. No claim is made that every original timing constant has been recovered.
