# Phase 1 — Mission clarity and reliability (0.1.158)

21 October 2026. Scope: the 116 original mission records, current guidance, prerequisites, rewards, failure/retry paths and story handoffs. No add-ons.

## Implemented corrections

- Guidance retains escort protection after rendezvous, distinguishes boarding already-disabled ships, displays deadline urgency and warns about mission-failing cargo scans.
- Offers/journals name actual cash, outfit, legal-record and military-clearance rewards. Original completion narratives remain intact.
- The 15 records with CanAbort=0 now reject voluntary abort at the service boundary and show a disabled Cannot Abort control. Acceptance screens warn of this commitment. Six unspecified CanAbort=-1 records retain their previous behavior.
- Failures explain missed deadlines, escaped assassination targets, lost escorts, destruction before boarding, escape-pod losses and obliterated destinations. Loaned equipment loss and retry locations are reported only when applicable.
- Failure popups no longer carry success status text. A failed repeat contract immediately cancels its mission autopilot with failure status, even when that contract ID was completed in the past.
- Map/port leads report actual faction and combat-rating requirements, including multiple unmet requirements. Bar offers retain the previously requested all-eligible listing.

## Verification boundaries

Final validation: 1,846 checks passed across 15 suites, including 760 Phase 1 checks and nine campaign routes. Native screenshots verified the journal and offer layout. The rebuilt 0.1.158 Mac app passed signature verification and a launch smoke test without script or preload errors; `git diff --check` passed.

`test_phase1_missions.gd` covers concrete initial/travel/return guidance and read-only/save-valid state across all 116 records, plus functional reward, abort, failure, retry, qualification and autopilot cases. Nine automated campaign routes exercise acceptance, actors, boarding, return completion, progression and disk reload. This is not a claim of manually playing every mission; full manual playthrough remains Phase 6.

Existing deliberate differences are retained: mission 224 PickupMode=5 is repaired as pickup-on-acceptance; original encounter cadence remains under separate fidelity work. Mission 185 keeps its source Topaz observation checkpoint despite broader Nexus-region briefing prose. Recent selected-weapon/Maverick firing preferences are preserved.

## Catalog coverage matrix

Generated from the recovered catalog; dynamic destinations and quantities are resolved and checked by the runtime tests. “Clock” below is the source deadline in game days, not a wall-clock timer.

| ID | Mission | Ship objective | Source reward | Voluntary abort | Clock |
|---|---|---|---|---|---|
| 128 | Ferry Passengers to &lt;DST&gt; | Travel/cargo | 10,000 credits | Allowed | None |
| 129 | Ferry Passengers to &lt;DST&gt; | Travel/cargo | 10,000 credits | Allowed | None |
| 130 | Ferry Passengers to &lt;DST&gt; | Travel/cargo | 10,000 credits | Allowed | None |
| 131 | Transport Criminal | Travel/cargo | 75,000 credits | Allowed | None |
| 132 | Smuggle Drugs | Travel/cargo | 100,000 credits | Allowed | None |
| 133 | Prospecting Expedition | Travel/cargo | 35,000 credits | Allowed | None |
| 134 | Gun Running | Board | 250,000 credits | Allowed | None |
| 135 | Rush Delivery to &lt;DST&gt; | Travel/cargo | 25,000 credits | Allowed | 31 days |
| 136 | Rush Delivery to &lt;DST&gt; | Travel/cargo | 25,000 credits | Allowed | 31 days |
| 137 | Rush Delivery to &lt;DST&gt; | Travel/cargo | 25,000 credits | Allowed | 31 days |
| 138 | Rush Delivery to &lt;DST&gt; | Travel/cargo | 25,000 credits | Allowed | 31 days |
| 139 | Rush Delivery to &lt;DST&gt; | Travel/cargo | 25,000 credits | Allowed | 31 days |
| 140 | Transport Cargo to &lt;DST&gt; | Travel/cargo | 10,000 credits | Allowed | None |
| 141 | Cargo Shipment to &lt;DST&gt; | Travel/cargo | 10,000 credits | Allowed | None |
| 142 | Cargo Delivery to &lt;DST&gt; | Travel/cargo | 10,000 credits | Allowed | None |
| 143 | Cargo Delivery to &lt;DST&gt; | Travel/cargo | 10,000 credits | Allowed | None |
| 144 | Freight Delivery to &lt;DST&gt; | Travel/cargo | 10,000 credits | Allowed | None |
| 145 | Hunt Pirate | Destroy | 75,000 credits | Allowed | None |
| 146 | Assassination | Destroy | 75,000 credits | Allowed | None |
| 147 | Stellar Defense | Destroy or drive off | 100,000 credits | Allowed | None |
| 148 | Rebel Defense | Destroy or drive off | 100,000 credits | Allowed | None |
| 149 | Rescue Mission | Board disabled | 50,000 credits | Allowed | 31 days |
| 150 | Salvage Convoy | Board disabled | 5,000 credits | Allowed | None |
| 151 | Escort Freighters to &lt;RST&gt; | Escort | 20,000 credits | Allowed | None |
| 152 | Investigate Dumping | Observe | No credits | Allowed | None |
| 153 | Observe Antares | Observe | No credits | Allowed | None |
| 154 | Capture Ore Sample | Board | No credits | Allowed | None |
| 155 | Destroy Freighters | Destroy | No credits | Allowed | None |
| 156 | Escape Astex | Travel/cargo | 1,000,000 credits | Allowed | None |
| 157 | Black Market Wood | Travel/cargo | 50,000 credits | Allowed | None |
| 158 | Environmental Trip to &lt;DST&gt; | Travel/cargo | 12,000 credits | Allowed | None |
| 159 | Defend New Cydonia | Destroy or drive off | 80,000 credits | Allowed | None |
| 160 | Defend Lethe Prime | Destroy or drive off | 100,000 credits | Allowed | None |
| 161 | Locate Rebel Fleet | Observe | 80,000 credits | Blocked | None |
| 162 | Rebel Interdiction | Destroy | 30,000 credits | Allowed | None |
| 163 | Rebel Special Ops | Travel/cargo | No credits | Allowed | None |
| 164 | Special Ops Insertion | Travel/cargo | Cloaking Device on acceptance | Blocked | None |
| 165 | Special Ops Rendezvous | Travel/cargo | 150,000 credits | Blocked | None |
| 166 | Confed Recon Mission | Travel/cargo | No credits | Allowed | None |
| 167 | Rebel Pursuit | Travel/cargo | No credits | Blocked | None |
| 168 | Rebel Pursuit Part 2 | Travel/cargo | No credits | Blocked | None |
| 169 | Rebel Pursuit Part 3 | Travel/cargo | 10,000 credits | Blocked | None |
| 170 | Rebel Pursuit Part 4 | Board | Particle Beam on completion | Blocked | None |
| 171 | Transport Confed Documents | Travel/cargo | 5,000 credits | Allowed | None |
| 172 | Transport Rebel Parcels | Travel/cargo | 5,000 credits | Allowed | None |
| 173 | Help Starbound Shipping | Travel/cargo | 10,000 credits | Allowed | None |
| 174 | Ferry Important Documents | Travel/cargo | 15,000 credits | Allowed | 60 days |
| 175 | Dangerous Courier Mission | Travel/cargo | 35,000 credits | Allowed | None |
| 176 | Escort Courier to &lt;RST&gt; | Escort | 30,000 credits | Allowed | None |
| 177 | Commerce Raid | Destroy | 50,000 credits | Allowed | None |
| 178 | Transport Engineers | Travel/cargo | 5,000 credits | Allowed | None |
| 179 | Retrieve Equipment | Travel/cargo | 10,000 credits | Allowed | None |
| 180 | Retrieve Colonists | Travel/cargo | 10,000 credits | Allowed | None |
| 181 | Get Repair Equipment | Travel/cargo | 10,000 credits | Allowed | None |
| 182 | Resupply Colony | Travel/cargo | 12,000 credits | Allowed | None |
| 183 | Defend Turin V | Destroy or drive off | 20,000 credits | Allowed | None |
| 184 | Investigate Disappearances | Observe | No credits | Allowed | None |
| 185 | Lead Rebel Patrol | Observe | No credits | Allowed | None |
| 186 | Rescue Rebel Spy | Board disabled | No credits | Blocked | None |
| 187 | Get War Records | Travel/cargo | No credits | Allowed | None |
| 188 | Locate Aliens | Observe | No credits | Blocked | None |
| 189 | Destroy Alien Cruiser | Destroy | 10,000,000 credits | Blocked | None |
| 190 | Investigate Disappearances | Observe | No credits | Allowed | None |
| 191 | Escort Confed Convoy | Travel/cargo | No credits | Allowed | None |
| 192 | Extract Confed Spy | Travel/cargo | No credits | Blocked | None |
| 193 | Locate Aliens | Observe | No credits | Blocked | None |
| 194 | Destroy Alien Cruiser | Destroy | 10,000,000 credits | Blocked | None |
| 195 | Derelict Decoy | Travel/cargo | No credits | Allowed | None |
| 196 | Derelict Decoy | Travel/cargo | No credits | Blocked | None |
| 197 | Ferry Passengers to &lt;DST&gt; | Travel/cargo | 10,000 credits | Allowed | None |
| 198 | Transport Cargo to &lt;DST&gt; | Travel/cargo | 12,000 credits | Allowed | None |
| 199 | Escort Courier to &lt;RST&gt; | Escort | 25,000 credits | Allowed | None |
| 200 | Switch Sides | Destroy | Rebellion record cleared | Blocked | 60 days |
| 201 | Deliver Kestrel Parts | Travel/cargo | 1,000,000 credits | Allowed | None |
| 202 | Cargo Delivery to &lt;DST&gt; | Travel/cargo | 12,000 credits | Allowed | None |
| 203 | Locate Weapons Cache | Travel/cargo | 50,000 credits | Allowed | None |
| 204 | Distribute Rebel Munitions | Travel/cargo | 35,000 credits | Allowed | 30 days |
| 205 | Dump Garbage | Travel/cargo | 20,000 credits | Allowed | None |
| 206 | Deliver Emergency Medical Supplies | Travel/cargo | 50,000 credits | Allowed | 21 days |
| 207 | Evacuate Civilians from &lt;DST&gt; | Travel/cargo | 50,000 credits | Allowed | 50 days |
| 208 | Evacuate Civilians from &lt;DST&gt; | Travel/cargo | 50,000 credits | Allowed | 50 days |
| 209 | Help United Galactic Express | Travel/cargo | 70,000 credits | Allowed | 30 days |
| 210 | UGE Recruitment | Travel/cargo | 75,000 credits | Allowed | 30 days |
| 211 | UGE Cargo to &lt;DST&gt; | Travel/cargo | 85,000 credits | Allowed | 30 days |
| 212 | UGE Delivery to &lt;DST&gt; | Travel/cargo | 105,000 credits | Allowed | 20 days |
| 213 | UGE Transport to &lt;DST&gt; | Travel/cargo | 90,000 credits | Allowed | 27 days |
| 214 | UGE Freight to &lt;DST&gt; | Travel/cargo | 100,000 credits | Allowed | 23 days |
| 215 | UGE Cargo to &lt;DST&gt; | Travel/cargo | 95,000 credits | Allowed | 26 days |
| 216 | UGE Delivery to &lt;DST&gt; | Travel/cargo | 120,000 credits | Allowed | 31 days |
| 217 | UGE Smuggling | Travel/cargo | 250,000 credits | Allowed | 45 days |
| 218 | UGE Smuggling | Travel/cargo | No credits | Allowed | 45 days |
| 219 | UGE Redemption | Travel/cargo | 50,000 credits | Allowed | 35 days |
| 220 | Confed Covert Ops | Travel/cargo | 40,000 credits | Allowed | 60 days |
| 221 | Confed Courier Operations | Travel/cargo | 60,000 credits | Allowed | 60 days |
| 222 | Intercept Rebel Convoy | Board | 60,000 credits | Allowed | None |
| 223 | Intercept Rebel Convoy | Board | 60,000 credits | Allowed | None |
| 224 | Transport Industrial Toxins | Travel/cargo | 35,000 credits | Allowed | 30 days |
| 225 | Deliver Refined Toxins | Travel/cargo | 45,000 credits | Allowed | None |
| 226 | Distribute Biological Weapons | Travel/cargo | 60,000 credits | Allowed | 30 days |
| 227 | Rebel Recon | Observe | 40,000 credits | Allowed | 30 days |
| 228 | Stop Confed Defector | Destroy | 80,000 credits | Allowed | 30 days |
| 229 | Destroy Rebel Convoy | Destroy | 100,000 credits | Allowed | None |
| 230 | Astrodyne Outpost Recruitment | Travel/cargo | 50,000 credits | Unspecified; unchanged | None |
| 231 | Astrodyne Outpost I | Travel/cargo | 20,000 credits | Unspecified; unchanged | None |
| 232 | Astrodyne Outpost II | Travel/cargo | 50,000 credits | Unspecified; unchanged | None |
| 233 | Astrodyne Outpost III | Travel/cargo | 1,000,000 credits | Unspecified; unchanged | None |
| 234 | Astrodyne Outpost IV | Travel/cargo | 50,000 credits | Unspecified; unchanged | None |
| 235 | Astrodyne Outpost V | Board | Tractor Beam on completion | Unspecified; unchanged | None |
| 236 | Ferry Passenger to &lt;RST&gt; | Travel/cargo | 30,000 credits | Allowed | None |
| 237 | Retrieve Data | Travel/cargo | 50,000 credits | Allowed | None |
| 238 | Rescue Agent | Board disabled | 50,000 credits | Allowed | None |
| 239 | Gather Hunters | Travel/cargo | 250,000 credits | Allowed | None |
| 240 | Meet with UGE Reps | Travel/cargo | 250,000 credits | Allowed | None |
| 241 | T.A.G. - You’re It | Destroy | 500,000 credits | Allowed | None |
| 242 | Destroy Escort Carrier | Destroy | 100,000 credits | Allowed | None |
| 243 | Destroy Escort Carrier | Destroy | 100,000 credits | Allowed | None |
