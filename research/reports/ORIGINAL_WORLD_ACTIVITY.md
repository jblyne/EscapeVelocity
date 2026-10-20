# World activity

Implemented news/disasters, planetary domination and tribute, and reputation-based landing clearance.

## Player access

- Ports: **Galactic news & tribute** opens a scrollable bulletin with local market events first, original story headlines, rotating original flavor news, and the list of tribute-paying worlds.
- Flight: select a world with 1–4 and press **H**, or use the ship-information screen's **Hail selected world** action. The channel explains the fleet size, tribute rate and reputation consequence before the player starts a battle.
- Defeat or disable all defense waves to obtain daily tribute. The channel also releases an existing tribute agreement. Travel days pay automatically. Reopening the screen or reloading does not pay again.
- Leaving the system, reloading, or landing elsewhere abandons an unfinished defense battle. Its progress is intentionally not saved; completed conquests are.

## Data and behavior

- The importer now retains all 52 original öops records. Valid market events use their source world, commodity, price delta, duration, frequency and mission-bit condition. Daily activation is deterministic, and active events persist through saves. Prices are modified in both the display and the actual buy/sell transaction, with a minimum of one credit per tonne.
- STR# 8101 supplies flavor news; 8102 supplies the five mission-linked news stories. Mission-linked records are activated once when their bits appear and expire after their source duration. Unused negative-duration records are ignored. Event 155 refers to Stellar 0, which is not a valid source world; it is retained in data but not assigned to an invented location.
- Planetary defense uses spöb DefDude and DefCount plus the source encounter's weighted ship list. Encoded values above 1000 use total=(DefCount-1000)/10 and wave size=DefCount%10. Rendering/contact limits are respected and resolved disabled defenders can be retired when slots are needed by later waves.
- Tribute uses max(TechLevel,1)*1000 credits per game day. MinCoolness is compared to the player's local government record. Non-landable objects reject landing; uninhabited worlds bypass reputation checks. Conquered worlds and cloaked approaches also bypass the reputation restriction. An active defense battle blocks landing on its world.
- Existing saves initialize world time at their campaign day, avoiding retroactive event simulation or tribute. New state validates IDs, bounds, duplicates and data types before applying it.

## Fidelity and sources

The original local resource forks establish the world events, descriptions, news, factions, reputation thresholds and defense records. The compatible wave encoding is documented in Matt Burch's [Nova Resource Bible](https://andrews05.github.io/evstuff/guides/evnbible.html); the [SpacePort conversion source](https://andrews05.github.io/evstuff/) preserves the old defense fields and explicitly derives tribute from technology level. These corroborate the reconstruction but are not a manual verification of every original 1.0.5 engine behavior.

Daily deterministic event selection, the three-second wave cadence, disabling defenders as a conquest condition, the demand reputation penalty, cloak clearance, and retreat/reload behavior are remake choices. No minimum combat-rating requirement or landing bribe has been added. Base commodity prices remain the existing prototype market; events modify those prices.

## Validation

- World-activity integration checks: real exchange transactions, event expiry, story unlocks, actual landing/refusal/revocation, source defense waves, kill/disable conquest, travel-day tribute, release, withdrawal, JSON persistence, duplicate-payment prevention, malformed saves and legacy saves.
- Regression checks: 151 campaign-route checks, 45 utility-outfit checks, and 73 communications/boarding checks passed.
- Rendered port, news, and planetary communications screens inspected at normal and small window sizes. Captures: builds/world-port.png, world-news-small.png, world-contact-small.png.
