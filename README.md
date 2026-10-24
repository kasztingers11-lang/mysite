# neoperro 1.3.20 - testing build

1.3.20 skips body-part scans for out-of-box candidates, skips repeated hidden
ESP/FOV writes, and lets TB use an eligible Silent point when its otherwise-unused
prediction fails. Independent activation, actual-body/shape and KO/wall checks remain.
Fixed pixel boxes and instant gun range changes are unchanged. Source and protected
mocks pass; live performance improvement remains unverified. See
[the live capture and repair notes](neoperro-handoff/docs/BOX-PERF-TB-REVIEW-2026-10-24.md).

FlowAuth distribution: [editable key/table/loader](neoperro-flowauth.lua) and
[build, upload and validation instructions](neoperro-protection/README.md).
Only the runtime upload is obfuscated; the table remains readable. Generated
upload files stay outside this public repository. Public development source and
its history remain available; obfuscation cannot revoke those copies.

1.3.18 introduced less restrictive Silent acquisition, screen-size boxes and
bounded Macro cleanup. Silent circle acquisition accepts the actual or predicted
point inside the same radius; AntiCurve keeps its configured final-coordinate
limits. Third-person Raycast can use a native muzzle surface, smoothing can recover
a fresh valid point, and the first actual target hit is no longer rejected by
cover behind it. Foreground cover still rejects. Shared edge-of-screen prediction
and one reused wall query reduce unnecessary rejection/work.

Boxes keep the user's **Height=4.3 / Width=5** values. A screen-size formula uses
exactly 16 pixels per unit, with no viewport scaling. Actual distance and
camera FOV never resize dimensions. Gun Specifications choose the same size units
by Close/Medium/Far distance, and ESP uses exactly those dimensions. Gun BoxSize
now has named Height/Width fields; legacy numeric pairs preserve their values.
No old 5x4.3 values need conversion. Macro actions retain normal timing but stale
phases and tool-action errors cancel cleanly, releasing owned Ctrl and attempting
restoration. Prediction discards expired ping contexts for all three features;
ESP visibility refreshes on substantial camera/target movement; duplicate hold-key
reads were removed. Other existing paths stay under regression.

1.3.19 explicitly removes the remaining viewport-size multiplier. Boxes change
instantly only on table edits or enabled gun-profile boundaries; no dimension
interpolation is used. Close/Medium/Far apply through 15/30/90 studs by default;
beyond Far the normal size returns. With Gun Specifications off, only the normal
configured size is used. The user reported distance resizing on a v1.3.18 session;
its exact serving payload and live cause were not verified.

Core/runtime and protected mock suites pass for 1.3.19. REAL was consulted only
for API documentation; no Roblox execution or live analysis occurred. This is not a live hit-rate,
FPS or provider-login result. See the [current review](neoperro-handoff/docs/SILENT-PIXEL-MACRO-REVIEW-2026-10-24.md).

The 1.3.17 update combines predicted XYZ part geometry with both forward camera and
native muzzle-to-mouse rays for Closest Point in third person. If the first part
fails final geometry checks, Closest can try another real body part; fixed BasePart
and exact Raycast surfaces stay fixed. Rejected points no longer seed smoothing.
Auto Y acceleration additionally needs matching position evidence. Triggerbot
checks a camera candidate completely before falling back to a native muzzle ray,
and uses real body height instead of helper hitbox height for Y math. Table values
are unchanged. See the [airborne/3D review](neoperro-handoff/docs/AIRBORNE-TRIGGER-REVIEW-2026-10-24.md).
All new results are offline; no new live accuracy result is claimed.

Auto Y now separates current contact from predicted landing support, ignores
remote FloorMaterial as a grounding decision, and follows verified continuous
ramp geometry in X/Z. Acceleration confidence no longer flickers with history/
render sampling phase, and a resolved Y velocity cannot inherit acceleration
from the rejected raw velocity. Custom/Offset behavior and table values remain
unchanged. See the [Auto Y review](neoperro-handoff/docs/AUTO-Y-REVIEW-2026-10-24.md).
No final live injection or hit-rate claim is made.

The preceding prediction/3D review fixes Closest Point on translated predicted
geometry, preserves fresh observed diagonal turns/braking, and keeps eligible
Silent routing during a held Triggerbot cycle. Direct vector transforms avoid
translation in ray directions. Manual/Auto rotated-part and exact-surface cases
pass for all three features, with one support query per accepted first candidate. Table values
and names are unchanged. See the [review](neoperro-handoff/docs/PREDICTION-REVIEW-2026-10-24.md).

The preceding update fixes a cursor/camera mismatch between Assist and Silent/Triggerbot:
Assist now aligns the actual cursor ray before the other features check it.
Eligible Silent coordinates can supply a Triggerbot-owned shot without changing
Triggerbot's activation or selection rules. All eight enabled/disabled feature
combinations pass mocks, including an off-center cursor with Triggerbot FOV off.
The revised collision fix has not been injected or tested live: the user's latest
instruction is to work offline.

Same-build table edits now update the running session without another HTTP fetch,
compile or FlowAuth launch. Cold loads still authenticate normally. Keep your own
key and edited table; replace only the old bottom loader with the release's
loader-only file. The complete starter contains defaults, not your private edits.
Whitelist assignments have no cap and an empty list allows everyone. Internal
posture sampling uses actual rig geometry and game animation IDs. ESP DisplayName
uses Humanoid.DisplayName when available, preserving tags such as [WINTER].

Use [neoperro.lua](neoperro.lua): edit the table and execute the whole file.
Its bottom loader fetches **repair/neoperro-evidence**. Main is older.
[neoperro-full.lua](neoperro-full.lua) contains the same table and runtime.

Earlier repairs fixed standalone ESP weapon profiles, removes the 60 Hz drawing and aim-selection caps,
recovers physically held activation keys, and adds shared muzzle/camera geometry.
Prediction uses bounded speed response, validated turn compensation and measured
vertical acceleration. Decelerating falls stop at rest instead of inventing a new
ascent. Horizontal/vertical resolver decisions are independent. Active Auto
estimates refresh every half second; supported hitscan guns add zero flight time. The table uses **Activation** and **Triggerbot check**;
older names migrate internally.

The aligned, comment-free table now uses Method, Closest.Selection, Unlock Method
and DelayMethod. Resolver, Anti-AimViewer and Client Bullets are global sections
above the targeting features. Y-Axis has per-feature switches and Custom Offset;
Auto ignores Offset. GroundShotCheck follows the shared three-column checks.
ESP boxes are unfilled, fully opaque and centered on the actual character;
prediction still affects shot points. ESP/box distance limits and Assist Ignore
are removed internally, including legacy overrides. Old tables migrate at startup.

Default controls: P Silent toggle, T Target selection, M Assist toggle, hold Q
Assist, V Triggerbot toggle, hold RMB Triggerbot, Z ESP, E unload.
A keybind's third entry selects Keyboard or Mouse. Re-execution retains valid
toggles; Enabled=false remains a hard gate.

Gun Specifications must be enabled with a supported gun equipped. Close, Medium
and Far are upper distance bounds; beyond Far uses the general size. Profiles
also change standalone ESP when the Silent box is hidden.

Live local fixtures verified profile ranges, Q/RMB selection and release,
third-person muzzle alignment/obstruction, and drawing on every frame at about
240 Hz. One native jump replay reduced vertical forecast error. These are not
server damage or hit-rate tests. Latest remote motion capture covered 15 players at about 200 ms Data Ping; native shot results remain inconclusive.
Lua regression suites pass; mocks do not prove Roblox compatibility.
Full and runtime bundles pass REAL static analysis with zero errors/warnings.

AntiCurve Max (studs) and Radius (pixels) accept 0.000000001 upward;
use math.huge for unlimited distance/radius. Defaults remain 2.2 studs / 120 pixels.
Muzzle obstruction and invalid geometry checks remain independent.

Prior 1.3.10 focused 15-player capture: 1,898 aim updates and draws on all 1,898 frames
over 8.0017 seconds (~237 FPS). Updates follow frames; this is not a fixed 240 FPS
guarantee. Selection/TB checks no longer wait for the 60 Hz history sampler.

[Settings reference](NEOPERRO.md) |
[Exact evidence and limitations](neoperro-handoff/docs/SESSION-2026-10-23.md) |
[Remaining validation](neoperro-handoff/docs/NEXT-SESSION.md)

Authoritative sources are neoperro-config.lua, neoperro-src/ and
neoperro-intro/preview.lua. Rebuild with python build-neoperro.py and validate
with python tests/run-lua.py tests/core.spec.lua tests/runtime.spec.lua.
The historical handoff snapshot/ZIP remains 1.2.0. Preserve local edits.
No executor credentials belong in the repository.

Historical 1.3.17 validation: Core/runtime/protected regression suites pass. Full, runtime,
readable starter and protected upload pass REAL static analysis with zero errors
or warnings. Static analysis does not execute Roblox or authenticate FlowAuth.
Earlier startup/config-update measurements are recorded separately in the session
log; they do not validate the final collision fix or remote hit accuracy.
