# v1.3.24 drawing layer repair - 2026-10-25

The owner reported boxes appearing black. Read-only REAL inspection of v1.3.23
found six visible foreground boxes still white (1,1,1), thickness 1, and black
outlines thickness 3. Both had ZIndex 0. This establishes ambiguous ordering,
not a configuration color change. The source did not assign explicit layers.

All outline drawings now use ZIndex 10, foreground boxes/circles 11, labels 12.
Native GUI fallback receives the same layer priorities. All foregrounds are
above all outlines, including overlaps across features/players. Colors, sizing,
feature behavior and v1.3.23 performance repairs are unchanged.

Existing live handles were assigned these priorities in-place, without runtime
reload, config changes or additional loops. This only patches current objects;
v1.3.24 is required for objects created later. The subsequent screenshot had no
visible boxes, so no visual before/after cure is claimed. Live diagnostics and
console had no reported problems before changes.

Source and protected runtime suites pass, including layer-order assertions on
native mock groups. Native Luau compilation passes. Provider authentication and
visual appearance after publication remain unverified.

FlowAuth upload: ../releases/neoperro-1.3.24/neoperro-flowauth-upload.obfuscated.lua.
Owner confirmed v1.3.23 publication; website PR #7 was merged/deployed and exact
v1.3.23 loader bytes verified with HTTP200 text/plain no-store. Keep website on
v1.3.23 until owner confirms v1.3.24 publication, then update version gate.
