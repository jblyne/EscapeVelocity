# Bar and landing mission trigger audit

Original local 1.0.5 catalog: 25 mission-computer records (AvailLoc 0), 84 bar records (AvailLoc 1), and 7 ship-contact records (AvailLoc 2). Location 2 is ship contact, not an automatic landing mission category; the original derelict and courier offer prose confirms this. The bundled original manual's Spaceport Bars section describes being approached while visiting the bar.

The remake previously exposed bar jobs only through the Bar Offers list. Entering the bar now selects an eligible original bar offer and displays its original offer narrative with acceptance/refusal controls. Original chance, progress, reputation, combat rating, cargo limits, journal capacity and cannot-refuse flag remain enforced. Resolved contacts are suppressed for the rest of the physical landing visit; the existing offer list remains available to reconsider jobs. Landing advances the visit seed, rather than requiring a hyperjump to refresh offers.

New approaches do not use AvailLoc 2 or invent an automatic landing job category. Existing mission load/delivery/completion reports trigger through game.land(), update progression and return to the port before the player visits the bar for follow-up contacts. Accepted bar approaches show the original briefing through the classic report dialog.

Validation: 12 real port/bar trigger checks, 284 mission interpreter/lifecycle checks, 457 checks across nine campaign routes, and 47 port presentation/service checks; zero failed checks. Rendered bar approach checked separately. Campaign route checks exercise progression through mission services, actors and save/reload; they are automated coverage, not manual playthroughs of every original encounter.
