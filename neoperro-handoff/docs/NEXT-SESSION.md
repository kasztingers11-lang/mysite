# Continue from 1.3.9

Use repair/neoperro-evidence and repository-root sources. Main and historical
snapshot/ZIP remain older. Preserve local edits and confirmed aim restoration,
native client pellet style, Macro Abuse, whitelist and intro behavior.

Implemented: shared forecast for all aim/box paths; XZ/Y resolver separation;
bounded speed/turn response; measured jump acceleration with braking-to-rest for
decelerating falls; active Auto target/weapon/ping estimates every 0.5 seconds.
Hitscan has zero travel time; do not invent projectile speed. Manual Value stays
the baseline and no Dynamic switch exists. Auto Y ignores JumpOffset.

Latest actual evidence is in SESSION-2026-10-23. Final remote capture: 15,576
forecasts per feature, zero falling-upward/grounded-lead violations at ~200 ms
Data Ping. Native shot results did not establish reliable damage. Local shared
Q/RMB fixtures passed and estimates refreshed in .500-.516 seconds. Predicted
visual stress in a populated server rendered on every frame at ~239 FPS.
Both bundles pass REAL analysis with zero errors/warnings; Lua regressions pass.
Mocks do not prove Roblox compatibility.

Next authorized work: move selection/Triggerbot checks from their 60 Hz schedule
to the client frame loop for 240 FPS responsiveness. Keep velocity fitting and
network/estimate sampling independently paced; measure populated-server cost and
preserve firing/cleanup semantics. No fixed FPS guarantee.

Still uncertain: controlled remote damage and shot-time eligibility transitions,
broad third-person weapon/obstacle cases, verified macro motion and calibration
across latency/replication states. Earlier public firing consumed two Revolver
rounds without observed target health loss; a DB send without ammo consumption
was not a confirmed shot. Focus loss/absent targets must never be counted as passes.
Key system, anti-tamper and webhook logging remain later work.

Before live execution inspect REAL health, diagnostics and console; use the full
bundle with the stable live-reload label. Never print/save executor credentials.
