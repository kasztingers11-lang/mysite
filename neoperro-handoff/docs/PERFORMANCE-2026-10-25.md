# v1.3.23 modest performance repair - 2026-10-25

FlowAuth remains the provider. The owner cancelled the PolSec migration; its
preparation files are historical and were never deployed to the website.

Position-only velocity regression now caches against the history table and
latest sample timestamp, independently of changing raw velocity. Resolution and
motion validation still read fresh raw XYZ on render updates. Histories shorter
than three samples retain the live raw fallback; respawns/history replacements
and new samples invalidate the fit. No aim, input, rendering or network cadence
was reduced, and no table values, feature checks or prediction formulas changed.

The same least-squares regression now accumulates XYZ as scalars and constructs
one final vector. The previous eight-sample implementation created 34 temporary
vectors. In the synthetic Lua54/Lupa table-vector benchmark, best of three runs
of 50,000 fits: previous 317 ms, current 54 ms. This isolates the regression and
is NOT a Roblox FPS/GC measurement or a whole-runtime speedup claim. The script
is tests/benchmark-velocity.py; native Roblox Vector3 costs will differ.

Validation: 720 XYZ/sparse-history cases match the prior regression within 1e-8;
source and protected full runtime suites pass, including raw changes without a
history tick, new-sample invalidation, sparse-history fallback and existing
prediction/input/TB+Silent/render/cleanup checks. Official Luau 0.744 compiles
source, bundles and protected outputs; core analysis is clean. REAL check-script
reports zero errors/warnings for full bundle and provider upload. The provider
variable is declared only in analyzer input, never in the distributed file.

Live evidence: get-game-info and console both report no injected Roblox client;
editor diagnostics are empty. No script was injected, changed or benchmarked in
a live client. The actual causes of intermittent FPS loss and latency remain
unconfirmed. Next: compare populated-server frame timings with the same camera,
movement and features before/after; distinguish ping from local frame delay.

Publish neoperro-flowauth-upload.obfuscated.lua from the v1.3.23 release directory
to the existing FlowAuth project. Keep the private key/table and canonical site
loader. Website currently pins v1.3.22; update its expected version only after
owner confirmation of the v1.3.23 provider publication, so warm ApplyConfig reuse
matches the new build. Provider authentication and live gameplay are untested.
