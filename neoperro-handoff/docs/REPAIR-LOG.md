# 1.3.19 fixed dimensions and instant range changes - 2026-10-24

User reports boxes resizing with player distance, Gun Specifications off, startup
version v1.3.18. That identifies the reported version, not the exact serving bytes.
Local v1.3.18 was already depth/FOV independent and passed mocks. The live cause
has not been established. Do not claim viewport scaling caused the report.

1.3.19 removes the remaining viewport-size multiplier entirely: Width*16 and
Height*16 are fixed pixels for ESP and selection. Body position can still move
on each render frame; no box-size interpolation or limb-fit resizing is present.
Gun Specifications off always uses the base size. When on, dimensions switch
immediately at configured physical range boundaries; default <=15 Close, <=30
Medium, <=90 Far, then base size. No proportional scaling within a band. Keep all
user table names, values, keybinds and independent feature behavior unchanged.

Core/runtime and the complete protected-runtime suites pass, including forward
and reverse range crossings and rendered pixel dimensions while distance, FOV
and viewport size change. The obfuscated upload matches BUILD.json. REAL API
reference only was read; no injection, live visual capture, provider login or
FlowAuth publication was performed. The user must publish the v1.3.19 protected
upload to FlowAuth; a website change alone cannot update that provider payload.

---

# 1.3.18 Silent acquisition, fixed pixel boxes and Macro cleanup - 2026-10-24

Prioritize Silent: allow actual OR predicted circle acquisition, exact native
muzzle surfaces in third person and fresh-point recovery after rejected smoothing.
Use first-hit muzzle visibility and reuse duplicate wall results. Keep final
AntiCurve limits, foreground blocking, whitelist/KO and exact/fixed-part semantics.

Per latest user instruction box values remain 5x4.3 with screen-size units:
16 pixels/unit at 1080p, scaled only by viewport height. Physical distance selects
gun profiles but never rescales dimensions; current camera FOV is irrelevant.
Named BoxSize fields and legacy pairs preserve numerical values. ESP/selection
share the same formula. No private keys/controls/colors/switches are replaced.
Shared review fixes Auto context expiry and movement-aware ESP visibility caches,
and removes duplicate hold-state reads. Existing feature/cleanup suites pass.

Macro cancels stale phases/overlong cycles and catches tool errors, releasing owned
Ctrl and attempting restoration. Normal delays and existing movement detection
remain. Shared full regression and protected-runtime suites pass. No MCP, REAL
static analysis, Roblox execution or real credentials were used. Live lag/hits/FPS
and published provider output remain unverified. See the current review.
Protected release is releases/neoperro-1.3.18 outside Git.

---

# 1.3.17 airborne Silent, third-person XYZ and Triggerbot - 2026-10-24

Prioritize Silent, then TB. Closest Point solves predicted XYZ geometry against
camera/native muzzle rays and can retry another real body part after final checks
reject the initial one. Fixed BasePart and exact surface semantics remain fixed.
Only accepted points seed smoothing. Record chosen ray/attempts separately from
final sends. Auto Y acceleration now also requires measured position support;
Custom/disabled semantics and all table values remain unchanged.

TB FOV-on uses the shared part fallback. FOV-off checks complete camera eligibility
before native muzzle fallback; helper HB/accessory dimensions no longer set real
body Y lead limits. Remove the unsupported Real Circle NumSides property write.

Core/runtime/protected suites, 1,452-case analytical replay and four REAL static
artifacts pass (zero errors/warnings). Added 9 feature/Y-setting fallback cases,
12 third-person timing/Y/side cases, 30 camera/physics/activation-send cases and
native helper/fallback regressions. No new live execution or observed damage.
See AIRBORNE-TRIGGER-REVIEW-2026-10-24.md for boundaries. Protected uploads remain
outside Git under releases/neoperro-1.3.17; no customer keys or credentials were read.

---

# 1.3.16 Auto Y - 2026-10-24

Separate current footprint contact from predicted XZ landing support. Remove remote
FloorMaterial grounding fallback. Follow bounded measured continuous-plane height
changes while grounded; never treat a separate raised step as an upward offset.
Suppress raw-derived acceleration after TrueVelocity replaces Y. Validate coherent
acceleration over a bounded sampling-time envelope, without adding age to lead.
Add ground/model diagnostics. Keep table values, Custom behavior and prior fixes.

New regressions reproduced the old failures and pass now. Core/runtime/protected
suites and four REAL static artifacts pass. Idealized 1,452-case replay isolates
sampling-phase improvement; it is not Roblox or shot-accuracy proof. No injection,
provider authentication or live damage test occurred. See AUTO-Y-REVIEW-2026-10-24.md.
Protected release files remain outside Git under releases/neoperro-1.3.16.

---

# 1.3.15 prediction and 3D follow-up - 2026-10-24

Fixed Closest Point against translated predicted geometry, evidence-gated acute
turns and same-sign braking, and held Triggerbot/Silent routing. Use direct vector
transforms for local ray directions. Reuse hitscan forecasts with one support query
and rebase trace data to the actual selected point. No table values/names changed.

New regressions reproduced failures in the previous implementation and pass now.
All-feature manual/Auto rotated-part and exact-surface cases pass, as do Core,
runtime and protected suites. Four REAL static artifacts are clean. No final live
injection or provider authentication occurred. Details and limitations are in
PREDICTION-REVIEW-2026-10-24.md. Final upload/starter are under releases/neoperro-1.3.15.

---

# 1.3.14 offline collision repair and session updates - 2026-10-24

Assist previously pointed the camera center at the target while Silent/TB tested
the actual cursor; selection also ran before Assist movement. This is a source and
modeled-projection finding, not a live reproduction of every reported collision.
Assist now rotates the actual cursor ray with the camera basis, then refreshes
projection before Silent/TB select. Triggerbot retains its click/eligibility while
an accepted active Silent point may supply coordinates. LastShotRoute separates
click source, aim feature and selected targets. No new feature switches were added.

Same-build starters update configuration in place without HTTP, compilation or a
second provider launch. Invalid tables cannot mutate the current runtime. Explicit
configuration wins over embedded full-bundle defaults. Update state preserves valid
unchanged toggles/locks/assignments and sampled history without adding listeners or
visuals. FlowAuth cold loads still authenticate normally. Loader phase timings are
reported without keys. The loader-only release file preserves the user's own table.

Whitelist empty lists permit everyone, configuration/assignment has no cap, and
membership is cached with explicit assignment invalidation. Internal posture
measurement uses actual rig geometry and cataloged game Animation IDs, including
generic live track names. Rotated parts use world height. Pose transitions reset
point smoothing/active estimates. ESP names prefer Humanoid.DisplayName for tags.

Core/runtime/protected regression suites pass: all eight feature switches, shared
hold/release, off-center cursor with TB FOV on/off, reverse camera rays, explicit
config propagation, 50 warm updates, 1,000 configured IDs and >4 assignments,
remove/add cache invalidation, crouch/prone/emote and [WINTER] name cases.
All four REAL static analyzers report zero errors/warnings. Protected tests use a
synthetic grant/hash backend. No final runtime injection occurred after the user
said 'dont inject js work'; final collision/pose/shot behavior is not live verified.

Earlier intermediate live measurements and the incorrect-default-table reload are
recorded in SESSION-2026-10-23.md. Do not reuse those stale wrappers or infer that a
default panic key caused the later absence of runtime. The user withdrew the crash
investigation. Actual FlowAuth authentication/publication and controlled remote
shots remain open. No credentials or real keys were read, saved or published.

---

# 1.3.12 protected distribution artifacts

Built the runtime upload with pinned Prometheus AST transformations, local-name
mangling, encrypted strings and shuffled constants. No VM interpreter, debug hooks,
busy-loop anti-tamper or crash routine was added. A FlowAuth grant gate and SHA-256
payload check stop cleanly before startup when authorization/integrity is missing.
This is not a guarantee against a client owner removing checks or deobfuscating.

The readable starter contains the supplied public FlowAuth loader, a placeholder
key, the full aligned table and simple feature/setting comments. Its parsed values
match the authoritative config. Runtime source is uploaded separately. Generated
release files are outside the public repo; no keys or credentials were collected.
Build instructions and attribution are in neoperro-protection/README.md.

Validation: the complete runtime suite passes against the protected upload using
synthetic grants/hash primitives. Four denied grant cases, payload tamper, missing
hash support, compiler rejection and valid integrity pass. REAL analysis with the
local grant fixture is clean. Native missing-grant and changed-payload cases
reject while preserving the existing runtime. The protected runtime loaded and
stayed alive in the empty server: six Drawings, matching 67,391 aim/draw updates,
mean aim .0571 ms and draw .0277 ms. Later observed six activations/ammo drops,
zero predicted sends and zero automated trigger attempts; no controlled targets.
Some block probes timed out while equivalent expression probes worked; cause
unknown. Console problems remained empty. Normal development runtime restored.

Actual FlowAuth publication, signed-key authentication and provider-produced output
remain untested until the user uploads/publishes. Public history still exposes
readable development source; protection does not revoke it. Other executors and
moving-player accuracy/performance remain unverified.

---

# 1.3.12 accepted table integration

Integrated the user's reordered, aligned and comment-free table. Canonical
names: Method, Closest.Selection, Unlock Method and DelayMethod. Resolver is
global; Anti-AimViewer and Client Bullets sit above per-feature settings and
retain the shared shot/restore/native-pellet paths. Y-Axis switches now apply
to each feature, with Offset for Custom; Auto ignores it. GroundShotCheck
is a Silent/Assist/TB array in Checks. Old names migrate with canonical precedence.

Removed Filled, Transparency, Predicted Position and Assist Ignore controls.
Boxes stay unfilled, fully opaque and on actual character positions. Removed
ESP and box distance caps completely, so old values cannot reinstate a cap.
Prediction and weapon profile ranges remain separate from these visual controls.

Mocks pass: canonical/legacy migration and precedence, all-feature Resolver,
Y-Axis/ground-check independence, fixed visuals despite legacy/live mutation,
one-million-stud on-screen ESP, and global Client Bullets/aim restoration for
Manual, Triggerbot and Prefire with Silent disabled, including both switches
off. Native pellet style/spread regression coverage is preserved.

Both generated bundles analyze with zero errors/warnings. REAL client rejoined
to generation 3; first game-info call timed out during that transition, then
recovered. Full 1.3.12 live-reload succeeded. Read-only state assertions passed:
alive, shared/global settings, removed fields absent, three ground columns,
33,522 aim updates, six FOV Drawing objects, zero remote records and zero
activations. Console problems were empty. This empty-server startup check
does not establish remote visuals, shot acceptance or hit accuracy.

---

# 1.3.11 resolver and table cleanup

Silent Aim now has Resolver.Enabled only; TrueVelocity is internal. Sampled
coherent XYZ movement can correct persistent reported-velocity mismatches with
separate horizontal/vertical confidence checks. Fresh transitions are preserved.
Velocity sampling and final Silent wall checks are always active. Removed the
EndMath table and its point visualizer, including the two Drawing allocations.
AntiCurve endmath is renamed Endmath, with startup migration for older tables.

Lua regressions cover persistent XYZ mismatches, fresh transitions, irregular
motion, teleport reset, live resolver toggles, legacy settings, mandatory wall
checks, FOV drawings and every-frame ESP/selection. Both generated bundles
pass REAL analysis with zero errors/warnings. A no-input Roblox Vector3 fixture
passed 3 correction and 3 transition cases plus irregular/teleport guards.
These are synthetic native-vector cases, not shots at actual anti-aim targets.
No full runtime reload, firing or damage test occurred in this batch.
No obfuscation, keys or logging was added; user table reorganization is pending.

---

# 1.3.10 frame cadence and AntiCurve range

Selection, Triggerbot checks and prediction/packet refresh follow each render
frame. History sampling and half-second active estimates keep separate pacing.
AntiCurve supports 1e-9 upward, with math.huge for unlimited distance/radius;
defaults/units and obstruction/invalid-geometry checks remain intact.

Focused populated capture: 1,898 aim updates and draws on all 1,898 frames over
eight seconds (~237 FPS). Both bundles analyze cleanly and regression suites pass.
This is frame-rate responsiveness, not a fixed 240 FPS or damage guarantee.
Computer Use was stopped with Escape; no further computer input was resumed.
See SESSION-2026-10-23 for exact evidence and remaining shot uncertainty.

---

# 1.3.9 remote-motion repair and active Auto estimates

Fixed an observed falling-to-upward error using a braking-to-rest rule; split XZ/Y
resolver decisions and apply fast-motion bounds across Silent/Assist/TB. Predicted
boxes now use the shared model. Active target/weapon/ping estimates refresh every
0.5 seconds without delaying motion updates; hitscan adds no projectile flight.
Both bundles now have zero REAL analyzer errors/warnings and mocks pass.

Public-server captures at roughly 186-200 ms Data Ping verified direction guards;
native shots did not establish reliable damage. Populated render and local shared
key/half-second fixtures are recorded separately. See SESSION-2026-10-23.

---

# 1.3.8 activation, profiles, rendering and shared geometry

Fixed standalone ESP bypassing weapon profiles; removed the drawing throttle and
pixel stepping; restored physically held activation state; renamed the requested
table fields with internal legacy migration. Added camera/native muzzle corridors,
feature-specific final wall origins, qualified vertical acceleration and validated
turn shortening. Existing aim restoration, native pellets and Macro Abuse remain.

Local engine profile/input/parallax fixtures, ~240 Hz drawing and one native jump
were observed. Both mock suites and generated syntax checks pass. No actual-player
combat was available; turn replay has a small mean/tail tradeoff and full-bundle
static analysis remains non-clean. Exact results and remaining uncertainty are in
SESSION-2026-10-23 and NEXT-SESSION.

# 1.3.7 reviewed checkpoint included

Cursor-ray AntiCurve distance replaces unstable raw background-surface distance;
TargetOnly filters candidates before selection; final-point walls, whitelist mode
retention, plain visual outlines/property caching and replacement cleanup improved.
The later 1.3.8 removes this checkpoint's 60 Hz visual cap and adds muzzle parallax.

---

# 1.3.6 prediction/Closest follow-up

Always-on bounded speed response in every prediction path, without a switch;
manual Value remains a baseline. Silent has a permanent high-speed horizontal
lead guard. Resolver validates historical forecasts against arriving positions;
Auto no longer double-counts sampler age at activation. Closest Point uses exact
ray/box geometry and honors real accessory surfaces in Raycast mode. See the
session log for replay metrics, live direction/ground counts, mixed shot results
and limits. Full audit, table organization and existing visual polish follow.

---

# 1.3.5 Character repair

Fixed native-HB/body mismatch in FOV-off Character scaling after reproducing it
with the actual cursor ray. Before/after sweeps verify selection expansion and
shrinking; firing was disabled. Mock occlusion and existing tracer/Macro Abuse/
aim restoration checks pass. No confirmed feature behavior was retuned.

---

# 1.3.4 shot-time aim-view follow-up

Continuous MOUSE overrides removed while Anti-AimViewer is enabled; explicit shot
coordinates are followed by a coalesced ordinary-aim restoration. See the session
log for one native manual hit with zero observed observer snaps and limitations.

---

# 1.3.3 pellet/macro follow-up

See SESSION-2026-10-23.md for native effect source evidence, spread/style checks,
Macro Check's game-derived velocity condition, removed ammo setting, and limits.

---

# 1.3.2 feedback repair

See [2026-10-23 evidence and changes](SESSION-2026-10-23.md). Two-client local tracer
separation and one Prefire response were observed; airborne follow-up lacked focus.
Expanded/shrunken trigger bounds, predicted FOV, gun-box separation and knocked ESP
pass mocks. Full details and limitations are in that record. Older history follows.

---

# Current status: 1.3.1 (2026-10-22)

See [session evidence](SESSION-2026-10-22.md) for the subsequent local REAL work and
[NEXT-SESSION](NEXT-SESSION.md) for current outstanding work. The older 1.2.0 log
below is historical: its branch, loader and no-local-MCP statements are superseded.
Current delivery branch is repair/neoperro-evidence; its loader uses that branch.

Final verification pass rebuilt identical outputs; both Lua 5.4 mock suites and
four syntax checks passed. No new code regression was revealed, so no speculative
runtime edit was made. No new live testing occurred during this pass.

---

# Repair evidence — 1.2.0

Branch: `repair/neoperro-runtime`. The repaired code and handoff are delivered on this branch; main retains the earlier build until merged. Complete live Roblox acceptance remains OPEN. After trying the full bundle, the user reported “it works okay,” but Auto Y still shoots the ground and Silent Aim needs further work. This is partial user feedback, not a controlled acceptance result. Passing Lua mocks does not establish shot acceptance, executor permissions, visuals, audio, or current game compatibility.

## Source of truth and build

Edit `neoperro-config.lua`, `neoperro-src/core.lua`, `neoperro-src/runtime.lua`, and `neoperro-intro/preview.lua`. `python3 build-neoperro.py` generates `neoperro-src/defaults.lua`, `neoperro.lua`, `neoperro-full.lua`, and `neoperro-runtime.lua`. The portable `source-snapshot/` was refreshed with these repaired files for transfer to the next local session; it is no longer the original baseline. The builder no longer rewrites its config input or creates the redundant `neoperro-config-updated.lua`.

The original checked-in full/runtime bundles differed from a fresh build before repairs. Fresh bundles are now generated from editable sources. The loader retains the commented config and final runtime loadstring; it still fetches **main**, so it will not fetch these local branch repairs until they reach main. To validate this revision locally, use this branch's complete `neoperro-full.lua`; do not confuse an old main download with the repaired bundle. The intro still fetches the documented immutable image/audio assets.

## Evidence by bug

| ID | Concrete finding and implementation | Verification / remaining work |
| --- | --- | --- |
| B01 | The existing Tool.Activated callback already sent MOUSE/Vector3, like Looten. A shared top-level final wall gate could reject every Silent point even when the feature's initial checks passed. EndMath is now Silent-only and explicit. Added `Diagnose()` to inspect equipped tool, remote presence, target IDs, send/activation counters and capabilities. | Mock shot payload routing passes. No claim that this explains every reported miss. Current games/weapon controllers and server acceptance need runtime evidence. |
| B02 | Old code waited Delay before pressing and released after fixed 0.04 seconds. Looten presses first and uses Delay as hold duration. Use one immediate press/hold/release cycle, random/smart hold alternatives, cancellation on activation/target loss, and native input with virtual/Tool fallbacks. Retain shot context across a failed input backend and refresh held target points. | Immediate press, no overlap, held duration, loss/release, shared activation and fallback behavior pass mocks. Live weapon timing is open. |
| B03 | Shared final EndMath wall gates applied to Assist as well as Silent. Moved these into Silent Aim. Assist keeps independent selection/prediction and hold-to-search. | Assist works in mocks with Silent disabled and with a muzzle obstruction rejecting Silent. Camera/native runtime behavior remains open. |
| B04 | Disabled and observed-macro guards already existed; walking alone is rejected in the existing mock. A recent ammo drop could be reused after a cancelled cycle. Consume each confirmed drop once; preserve live disable and owned Ctrl cleanup. | Disabled, walking, observed I/O alternation, fresh ammo confirmation, consumed confirmation and live cancellation checks pass. External macros that do not expose inputs are not detectable by this heuristic. |
| B05 | Every rendered style required its Visible flag; hiding Silent style removed standalone ESP. Added independent root-centered 6x6 fallback, unaffected by weapon profile or hidden Silent distance. Visible Silent style still overrides. Isolate rendering errors per player. | Stable dimensions, hidden style fallback, dead checks, names, colors and one failing player's Drawing pass mocks. Actual overlay geometry remains open. |
| B06 | Disabled whitelist still restored assignments and applied markers; assignment input remained active. Clear on initialization and heartbeat, skip restoration/assignment, gate marker colors. | Disabled assignment/removal, replacement, enabled friend/target filtering and colors pass. |
| B07 | Tool changes/respawn did not immediately release held automated input. Input backend failure could lose cycle metadata. Added release on weapon/character removal and startup generation guard around yielding PlayerGui lookup. Existing hook dispatchers remain shared; cleanup remains owned. | 20 replacements alternate source and generated runtime, keeping one render binding and constant connection count; old drawings removed and mouse released. Final teardown removes all Drawings. Concurrent yielding startup and real executor hooks still require live checks. |
| B08 | Trigger prediction default was 0.132 instead of 0.121. Corrected it; lead is applied once in seconds. History remains bounded and reset on discontinuities. Auto/Custom Y behavior remains explicit and mutually exclusive. | Math/history and Custom/grounded Auto checks pass. Looten's resolver is a heuristic; its fixed speed-16 movement fallback was reviewed, not copied as authoritative velocity. User now reports Auto still shoots the ground. This follow-up is NOT FIXED; investigate live vertical intermediates and the shot endpoint. Existing grounded Auto mocks do not cover or resolve the reported failure. |
| B09 | Exposed degree limits and a world-space lead clamp contradicted distance examples. Removed MaxAngle and top-level EndMath. User confirmed 3d-angles Max=2.2 studs from ordinary Mouse.Hit and endmath Radius=120 pixels around cursor. Reject outside the selected radius; do not truncate lead. | Distance rejection/accepted unmodified lead and config shape pass. This is an explicit user-confirmed interpretation, not a recovered Looten algorithm or server guarantee. |
| B10 | Looten exposes Anti-AimViewer switches but supplies no complete corresponding algorithm. Preserve shot-scoped MOUSE updates and idle pass-through. | Idle pass-through and shot redirection pass mocks. Spectator/admin concealment is unverified and not promised. |
| B11 | Shared keys already dispatch to all matching actions. Preserved that path while separating final filters and owned input lifecycle. | Shared Q/P inputs, focus/typing, respawn, Panic enabled/disabled, GUI fallback and replicated-ammo Prefire pass mocks. AntiAfk, AntiFling, arbitrary tracers, and interactions in current games remain live checks. |

## Looten comparison and API evidence

`Looten` and `references/Looten.reference.lua` contain the same code except for one trailing newline. Relevant inspected areas:

- Lines 148–175: game table uses MAINEVENT/MOUSE but **different place IDs** from the requested three. The user confirmed these are old IDs. The active runtime deliberately uses the user-supplied current IDs: Da Strike 134196333708867, Da Uphill 71324444457408, Da Downhill 139144803593140. This is not a configuration blocker; live shot acceptance remains untested.
- Lines 670–800: target point/velocity calculation, resolver movement heuristics, falling adjustments, and Tool.Activated MOUSE/Vector3 updates. Neoperro retains/adapts the activation send pattern with its own config, eligibility and lifecycle; no bulk copy or numerical reuse percentage is claimed.
- Lines 1406–1417: native Mouse.Target ancestry, press, wait Delay, release. Neoperro adapts this sequence with ancestry walking, a portable raycast fallback, hold activation, non-overlap and cancellation. The native path is preserved rather than requiring Tool.Activate alone.
- Resolver movement fallback multiplies MoveDirection by 16 and prediction; it is not recovered authoritative velocity. Existing timestamped history remains an explicit alternative, with no compatibility claim.

Official Roblox API reference source was retrieved during this repair from `Roblox/creator-docs` on GitHub. It confirms that Mouse.Target can be nil, Mouse.Hit is a world CFrame, Tool.Activated is a click event and does not fire with Ctrl pressed, and GetMouseLocation/viewport projections do not apply the GUI inset. This runtime uses raw mouse/viewport coordinates and IgnoreGuiInset overlays. Native Ctrl macro behavior must therefore be checked with actual activation.

- [Tool](https://create.roblox.com/docs/reference/engine/classes/Tool)
- [Mouse](https://create.roblox.com/docs/reference/engine/classes/Mouse)
- [Camera](https://create.roblox.com/docs/reference/engine/classes/Camera)
- [UserInputService](https://create.roblox.com/docs/reference/engine/classes/UserInputService)
- [GuiService](https://create.roblox.com/docs/reference/engine/classes/GuiService)

No new developer-forum evidence is claimed. Neither the API reference nor the screenshots establishes game-specific remotes, anti-curve guarantees or executor compatibility.

## Commands and outcomes

`python3 build-neoperro.py`: successful regeneration. `python3 tests/run-lua.py tests/core.spec.lua tests/runtime.spec.lua`: both assertion suites pass; four generated/config Lua files compile under Lua 5.4. The runtime suite also executes the generated runtime during repeated replacement, not just the editable body. The cloud agent ran no live engine, network loader, server damage or visual/audio test. The user subsequently reported the full bundle works okay, with Auto Y ground shots remaining; no controlled game/weapon/runtime evidence was supplied. A zero-test syntax-only result is not being counted as functional validation.

## Short in-game checklist

Use a private test session you control. Start with this revision's full bundle; check `Version` is `1.2.0`.

1. One feature at a time: Silent Auto and Target with each supported weapon; distinguish target selected, MOUSE packet sent, and damage accepted. Record place/weapon/runtime/error and failures.
2. Trigger: hold/release activation, lose the target, reload/empty ammo, swap weapons and respawn; verify every press is released. Try shared Q with Assist.
3. Assist with Silent off, then on; hold-to-search must retarget, releasing stops it.
4. Re-execute repeatedly, including during mouse hold and macro Ctrl hold. Expect one overlay/runtime, no stuck input, and one intro per session. Panic cleans everything.
5. Hide Silent box: ESP remains 6x6. Test death, whitelist enable/disable/re-execution and both assignment modes. Macro disabled/walking must do nothing; eligible shots require a fresh ammo decrease and observed macro inputs.
6. Only after the basic shot works, test prediction, Auto/Custom Y, each AntiCurve mode separately, and intro appearance/audio. Record accepted/rejected geometry rather than assuming a modifier fixes server shots.

For a console report (no secrets), run:

```lua
local r = getgenv().__neoperroRuntimeV1
if r then
    local d = r:Diagnose()
    print('Version', d.Version, 'Tool', d.Equipped, 'Remote', d.Remote)
    for k,v in pairs(d.Targets) do print('Target', k, v) end
    for k,v in pairs(d.Stats) do print('Counter', k, v) end
    for k,v in pairs(d.Capabilities) do print('Capability', k, v) end
    for k,v in pairs(d.Warnings) do warn(k, v) end
end
```

Real MCP shown by the user is a Windows-local server. This cloud machine cannot reach that PC's loopback server. Connect it to a local Codex client on that PC, start a new session, and continue using this branch's changes. No Real MCP tool is available in this cloud session.

## Latest continuation status

See [NEXT-SESSION.md](NEXT-SESSION.md). The user is moving to a local Codex chat with Real MCP to diagnose Auto Y ground shots and improve Silent Aim from Looten evidence. No runtime changes were made as part of this handoff refresh.
