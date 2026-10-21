# Original star map reference

The local Escape Velocity 1.0.5 distribution supplies the reference: `Escape Velocity Documentation.rsrc`, **PICT 2008**, and the manual TEXT section beginning “Another helpful dialog you can access is the star system map.” The original picture is 440 × 396 pixels. No later EV Nova interface was used.

The chart occupies approximately (10, 9)–(308, 307); the right-hand information column begins at x=314. Ports and navigation hazards sit below the chart; zoom controls sit at the lower left and Done at the lower right. The screenshot shows the minus button; the text explicitly specifies both + and − controls. The route-planning paragraph explicitly names Clear Route.

The manual specifies green selection brackets, a blue current-system center, blue friendly/neutral systems, red hostile systems, light-grey uninhabited systems and dark-grey unexplored systems. Dragging pans, C recenters, Tab/Backslash cycle connections, and Shift-click appends connected route stops. The picture also shows red mission arrows at the chart boundary.

The missions section specifies red arrows for accepted missions and a green destination arrow when M is pressed while considering an offer. The mission interpreter already honors source flag 0x0002 for suppressed accepted-mission arrows; this remains intact.

The remake rebuilds the frame at twice these design coordinates and scales it to the window. It uses current game state for reputation, services, available trading goods and surviving worlds. Original market pricing and per-port landing-history discovery remain separate parity work. Planned routes remain in memory; ordinary hops require another J press, while the preexisting chain-jump cheat remains automatic.

## Dominated systems — 0.1.160

The original 1.0.5 map draws each system ring through color helper 0x63420 (call at 0x3c89c–0x3c8ac). That helper counts inhabited, tribute-paying worlds using the stellar runtime byte at +0x20, and overrides ordinary legal-status colors at 0x63684–0x63698 when at least one pays tribute. The selected color is the bright green RGB structure at TOC -0xc58 (green initializer 0x64d8c–0x64dd0). The blue current-system center and green selection brackets are separate drawing operations.

The remake now colors a system ring bright green when at least one surviving world pays tribute. Selected details show **Dominated**, with the tribute-paying world names in a tooltip. Other ports in a partially dominated system retain their existing independent gameplay rules. Releasing the last surviving tribute agreement restores ordinary map coloring; obliterated worlds cannot leave a false domination indicator. Existing saved domination state drives the indicator without a migration. Conquered systems remain known even when an older save lacks their exploration flags.
