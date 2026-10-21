# Original bar-entry and idle encounter trigger

Verified against the local original Escape Velocity 1.0.5 PowerPC executable. This supersedes the immediate-entry presentation and physical-landing reroll introduced in 0.1.86.

- 0x9808 is the bar routine, called from the port handler at 0x41378.
- 0x987c–0x98d8 compares the previously visited bar port with the current port before refreshing the random table and candidate list. The table uses 256 rolls, each Random(100)+1.
- 0x9918–0x99f8 orders flag 0x1000 candidates before others.
- 0x9a20–0x9a34 initializes the idle counter to Random(100)+80.
- 0x9abc–0x9b34 creates and draws dialog 1013 (Bar). The normal dialog event loop follows. It does not present a mission inside the entry button handler.
- 0x9d40 and 0x9d84 reset the counter for keyboard/mouse activity. 0x9e2c–0x9e68 increments it and compares against Random(150), emitting synthetic item 6 when it passes.
- Item 6 dispatches 0xb65c at 0x9c74. That routine calls the original mission offer presenter at 0xb6ac, removes the handled candidate, and resets the idle counter.

The remake prepares a stable same-port candidate pool, respects original eligibility and priority, and presents contacts through a bar-only idle scheduler after the opening animation has finished. Input resets the idle counter. Different bars refresh the chance pool; physical landing alone no longer rerolls it. Acceptance revalidates all non-chance prerequisites against the already-rolled approach. Pilot loading resets transient bar encounter state. Existing Bar Offers remains a manual convenience.

The source is event-count based, not a documented seconds delay. Its counter ranges are preserved at a nominal 60 idle events/s for the modern engine; this does not claim identical wall-clock cadence on every vintage Mac.

Validation: 17 bar/landing trigger checks, 47 port UI/service checks, and 284 mission interpreter checks, with zero failures. Separate captures verify that the bar renders before a queued approach.
