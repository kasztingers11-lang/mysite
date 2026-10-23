# Continue from 1.3.10

Use repair/neoperro-evidence and repository-root sources. Main and historical
snapshot/ZIP are older. Preserve local edits and user-confirmed aim restoration,
native client pellet style, Macro Abuse, whitelist and session-once intro.

Implemented: shared XYZ forecast for all features/boxes; separate XZ/Y resolution;
speed/turn bounds; measured jump acceleration with braking-to-rest for decelerating
falls; active Auto target/weapon/ping estimates every 0.5 seconds. Hitscan adds no
travel time; no invented finite bullet speed. Manual Value remains its baseline,
no Dynamic switch. Auto Y ignores JumpOffset and Custom remains separate.

Selection/Triggerbot checks now follow render frames; history and network work
remain paced independently. AntiCurve Max/Radius accept 1e-9 upward or math.huge
for unlimited distance/radius. Defaults remain 2.2 studs / 120 pixels. Geometry/
wall checks remain independent.

Latest focused capture: 15-player server, 1,898 aim updates/draws on all 1,898 frames
in 8.0017 seconds (~237 FPS). Prior 1.3.9 capture: 15,576 forecasts per feature,
zero falling-upward/grounded-lead violations at ~200 ms Data Ping. Shared Q/RMB
local fixture and half-second refresh checks passed. Both generated bundles have
zero REAL analyzer errors/warnings; Lua regressions pass. Mocks do not establish
Roblox compatibility.

Still needed: controlled actual-player damage and shot-time eligibility testing,
broad weapon/obstacle/third-person cases, verified macro movement, and further
latency calibration. Public native shots consumed two Revolver rounds without
observed health loss; DB sends without ammo consumption were not shots. Existing
evidence does not prove perfect prediction or every hit.

Computer Use reported a physical Escape stop. Do not resume computer input in that
stopped turn. Preserve focus-loss guards and cleanup. Inspect current REAL health,
diagnostics and console before any newly authorized live continuation. Use rebuilt
full bundles and the stable live-reload label. Key system, anti-tamper and webhook
logging are later work. Never print/save executor credentials.
