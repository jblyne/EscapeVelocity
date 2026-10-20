# Original mission and outfitter screens

Reference images come from the local verified Escape Velocity 1.0.5 documentation resource fork:

- PICT 2012: 516 × 206 mission computer. Scrollable list at left, green selected row, serif mission heading and original briefing at right, Leave and Accept Mission along the bottom.
- PICT 2013: 452 × 158 active journal. Left list, right quick briefing, date at upper right, Abort Mission and Done below.
- PICT 2016: 500 × 265 outfitter. Four-column icon grid with counts and green selection outline at left, equipment description at upper right, price/balance information and selected-item picture below, transaction/leave controls at bottom.

The remake rebuilds these at twice their design coordinates with native controls, a maximum display scale of 1, and scaling down when the window requires it. The mission list is an ItemList and the briefing panes scroll independently; equipment uses a four-column GridContainer. Existing generated 3D equipment models are retained, with black backgrounds instead of blue cards. No new image generation was needed.

Original mission offer and QuickBrief text remain supplied by the mission interpreter. Outfitter prose comes from the original desc 3000 + outfit ID − 128 records, with the existing functional description as fallback. Mission computer and bar offers are opened separately from their corresponding landing actions. I opens the active journal; M previews selected mission destinations. Source mission validation, cargo limits, eight campaign slots, original flags, stock/technology restrictions, prices and equipment effects remain unchanged.

The authored introductory courier appears as an ordinary mission-computer row, has its existing acceptance/payment rules, and now also appears in the active journal. Aborting that courier releases its five tonnes of mission freight without payment. Reports appear in the right pane and selecting another row dismisses them.

Validation: `test_classic_services.gd` covers native list selection, original prose, map round-trip selection, accepting and aborting campaign missions and courier contracts, flight/port return modes, compact sizing, four-column equipment selection, original item descriptions, unchanged purchase/sale behavior and disabled transactions. Its visual mode captures offer/journal/outfitter screens at 1440 × 900 and 1000 × 650. Updated existing landing tests select the courier row before accepting; outfitter tests check the classic grid instead of the removed category filters.
