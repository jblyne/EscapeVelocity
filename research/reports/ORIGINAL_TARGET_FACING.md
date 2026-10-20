# Hold-to-face guidance

The recovered Escape Velocity 1.0.5 manual (`research/decoded/original-manual.txt`, line 276) explicitly describes holding A to align the ship toward Levo after requesting landing clearance. Its flight-controls section (lines 265–267) distinguishes facing from thrust and preserves inertial drift.

A contemporary player recollection describes the same A control facing a selected ship, or a planet when no ship is selected: https://www.reddit.com/r/endlesssky/comments/x894ez/ . This is corroboration, not an independently observed original-executable test.

Implementation: hold T because this reconstruction already uses A for left turn. Recompute the direct bearing every physics step, use the existing maneuver-limited steering, prioritize the selected ship and otherwise the selected landing body. Do not add thrust, automatic firing, predictive lead, braking, or a persistent lock. Manual turning and retrograde steering override it. Hyperspace and paused modes retain their existing control ownership.
