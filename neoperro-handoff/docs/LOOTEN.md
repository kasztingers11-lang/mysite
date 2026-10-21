# Looten reuse requirement

The user requested “make it 70% Looten” because previous implementations failed and they want Looten's relevant established paths used as the starting point. This is a user preference, not a measured property of the existing build. Do not claim that a numerical percentage was achieved, copy unrelated features to inflate it, or expand the script to 15,000 lines for appearances.

References:

- [Supplied Looten snapshot](../references/Looten.reference.lua)
- [Original Looten file](https://github.com/kasztingers11-lang/mysite/blob/main/Looten)
- [Goodnight configuration snapshot](../references/goodnight.reference.lua)
- [Original Goodnight file](https://github.com/kasztingers11-lang/mysite/blob/main/gn)

## Evidence from the inspected source

- Looten calculates its Silent target point and sends coordinates from a Tool.Activated path. The relevant source area is approximately lines 670–800. Compare the actual game-specific remote lookup and argument rather than assuming a generic remote.
- Its resolver uses velocity/movement heuristics, with special falling behavior. These are heuristics, not recovery of authoritative server velocity.
- Triggerbot checks Mouse.Target ancestry for a character, presses the mouse, waits its Delay, then releases. See approximately lines 1406–1417. Preserve intended timing while fixing overlapping execution and input cleanup.
- The source contains AntiCurve and Anti-AimViewer configuration switches, but inspection did not find corresponding complete algorithms to transplant. Do not invent implementations and label them Looten's.
- Looten's I/O macro behavior is evidence about its own inputs. The requested shot/unequip/Ctrl/equip continuation is additional behavior and needs its own verification.

## How to record reuse

For each adapted function, record the source function or line area, its role, changes made for neoperro's table and lifecycle, and tests. Keep source provenance separate from performance claims. Review source licensing/permission before redistributing adapted code; no license grant is established by this handoff.

The user's request to consult forums remains relevant research work. No new forum research was performed while preparing this package. Existing source-snapshot documentation contains older links and claims; verify each relevant claim against the actual source before relying on it.
