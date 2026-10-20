# Original ship communications and boarding

Reference checked September 20, 2026, for build 0.1.19.

## Evidence

The local original Escape Velocity 1.0.5 documentation resource fork, decoded in
`research/decoded/original-manual.txt`, establishes:

- TEXT 132: Tab selects a ship; Y opens communications. Responses and buttons
  depend on the ship. Hailing can provide information, work, or fuel assistance.
- TEXT 134: hailing an escort offers Release Escort.
- TEXT 135: B boards a disabled ship when overlapping it and approximately
  matching its heading and velocity. The separate plunder panel offers cargo,
  credits, ammo, fuel, capture, and abort. Repeated plundering increases the risk
  of self-destruction. Capture odds depend on crew strength.

The source EV Data STR# 3000 communication strings corroborate friendly and
hostile responses, refusal when no rescue is needed, paid refueling, assistance
en route, and negotiated payments. Government records provide ShootPenalty,
DisabPenalty, BoardPenalty and KillPenalty.

I also operated the original game in the retained Infinite Mac Mac OS 7.6 Chrome
session. From the title screen, Enter Ship returned to Levo. Tab selected a
Militia Defender; Y opened a compact paused dialog with:

- Captain response at upper left and ship portrait at right.
- Alignment and type: Militia Fighter.
- Buttons: Greetings, Request Assistance, End Communication.
- Initial response: “Channel open.”
- Request Assistance, while fully fueled, responded “You're not in any trouble.”

The emulated original’s patch version was not independently confirmed. Boarding
and bribe behavior here is grounded in the local manual and resource strings;
the emulator observation directly verifies the hail layout and assistance
refusal only. The reference session was left paused in communications.

## Implemented

The remake preserves Tab then Y, the three observed communication choices, a
ship portrait, faction, and captain response. It adds Offer Bribe and an Attempt
to board shortcut to that panel; B remains the direct boarding shortcut. The
old B combat drill moved to Shift+B. Escape closes either dialog, and Y closes
communications. Flight, weapons, and traffic pause during interactions.

Friendly ships with spare fuel can rendezvous with a pilot who has less than
one jump of fuel. The donor moves toward the player and matches motion before
transferring 100 fuel. The quoted payment is taken only on transfer; timeout,
attack, insufficient credits, and loss of need cancel without charging. A ship
keeps at least one jump of its own fuel. Infinite-fuel pilots do not need rescue.

A paid bribe pacifies that contact for the current system visit, recalls its
active attacks at the player, and does not erase government reputation. Further
player attacks on that ship or an allied military ship break the ceasefire.
Alien factions do not negotiate intelligibly. These prices and acceptance
rules are provisional, not decoded original engine decisions.

NPCs retain the prototype's combined integrity pool. Surviving damage at or
below 15% integrity disables engines and weapons; lethal damage still explodes.
Disabled ships keep their heading and drift to rest. The target panel and
scanner identify them in gray. NPCs and debug escorts stop attacking disabled
targets automatically; the player can still fire manually.

Boarding requires the player's center within the target radius (minimum 25
units), relative speed at most 25, and headings within 30 degrees. The dialog
transfers credits, cargo and fuel, respecting the shuttle's 20-ton hold including
mission cargo and its existing debug fuel capacity. Empty transfers cannot
repeat; remaining goods stay aboard. Taking goods advances a visible
self-destruct risk, starting at 3% and increasing by 3 percentage points per
successful transfer to a maximum 30%. Self-destruction ends boarding and damages
the player's shield/armor using the existing combat rules.

First disabling and first boarding apply the original faction's corresponding
penalties. Player rewards save immediately using the existing compatible pilot
format. Contacts, their inventories, ceasefires and appointments are transient,
as the prototype regenerates traffic on loading or entering a system.

## Limits and tuning

Exact original disable thresholds, range, speed/heading tolerances, prices,
inventories, assistance AI, and self-destruct probabilities are unverified.
Source ship crew, hold, cost and fuel values inform generated NPC inventories.
Dialogue beyond the short observed greeting is authored for this remake.

This adds playable hailing and salvage boarding, not the complete original
capture/escort or mission-dialogue systems. Taking command of a captured ship,
persistent captured escorts, escort release, ship-offered missions, and hailing
worlds are not implemented. Ammo plunder is not offered because the current
purchasable player loadout uses ammunition-free lasers; the debug arsenal
already has unlimited ammunition. No nonfunctional capture/ammo buttons are
presented as usable actions.

## Validation

55 dedicated headless checks cover keyboard and menu actions, paused simulation,
fixed selected contact, rescue need, actual donor rendezvous, payment once,
unaffordable/expired requests, bribery, persistent ceasefire and breaking it,
recall of in-flight attacks, disable behavior, distance/speed/heading gates,
source boarding penalty, capacity/mission protection, repeated-transfer guards,
valid pilot saves, stale target cleanup, load/reset, hyperspace gating, the debug
shortcut, and self-destruction. Existing feature suites are also run for combat,
travel, menus, ships, sound and visuals. Graphical review covers the three main
interaction panels at the minimum supported window size.
