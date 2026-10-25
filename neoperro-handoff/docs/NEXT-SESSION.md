# Current distribution task: PolSec migration pending public loader

Read POLSEC-MIGRATION-2026-10-25.md. The PolSec v1.3.22 upload is ready outside Git;
its gameplay payload is unchanged. Bootstrap/provider label and integrity guard
are tested. Core/runtime/protected mocks, native Luau compilation and REAL static
checks pass. No actual PolSec auth or provider output has been tested.

The owner still needs to publish the upload and send the generated public PolSec
loader URL. Then switch/test/deploy Fosternya's bridge for that provider. Until
then production remains on the already published FlowAuth v1.3.22 bridge.
Preserve the private edited table, and never request an account API secret.

---

# Current continuation: v1.3.22

Read INPUT-PREDICTION-REVIEW-2026-10-25.md first. Delayed native TB/Silent activation
was reproduced on v1.3.21 in a mock and repaired. Keys, automatic same-session
config edits, signed XYZ motion, body-frame model selection, manual ping adaptation,
TrueVelocity oscillation handling and less restrictive Y/Endmath paths are updated.
The global macro-specific lead-time cap is removed; AntiCurve judges final geometry.
No table names/values changed. Core/runtime and protected suites pass. Official
Luau compilation passes; pure core.lua analysis is clean.

REAL is absent from the current tool inventory despite the owner reconnecting it.
No new live result, native hit rate or FPS is claimed. Prior frozen client state
must not be probed repeatedly; inspect fresh diagnostics before live changes.
Next live checks: native TB+Silent clicks with Anti-AimViewer on/off, toggle and
activation combinations, in-place config edits, normal/tiny torsos jumping/falling/
strafing at high ping, and AntiCurve in third person across weapons/obstacles.
Compare selected part/velocity/model/point, sent MOUSE and actual damage separately.

The owner confirmed publishing v1.3.22 to FlowAuth. Website PR #6 is merged
(574bdbed9fb5c9281772c5c880dd3c6c6123cd05); Vercel reports success, and production
/loader.lua matches v1.3.22 byte-for-byte: HTTP 200, text/plain, no-store.
REAL tools subsequently reappeared. Its static checker reports zero errors and
warnings for the full bundle and the protected upload (provider variable declared
only in analyzer input, never in the release). No live execution or gameplay
verification occurred. REAL API notes warn that getgenv views can differ between
chunks; cross-execution config visibility still needs native verification.
Keep their existing private key/table and canonical site loader. No new settings
or value conversion are needed.

Earlier checkpoints, publication notes and pixel-sizing assumptions are historical.

---

# Work in progress: v1.3.22 input, shot routing and prediction

The owner requested Silent/prediction and native-click TB cooperation first,
then keys/config updates, moving the global macro lead cap into AntiCurve,
less restrictive ground behavior, body-aware uncertainty and TrueVelocity repair.

First checkpoint: reproduced the delayed native Tool.Activated failure on the
v1.3.21 runtime in a mock. Its earlier aim restore can precede native activation;
TB did not send the redirected point again. Activation now resolves and sends a
fresh TB/Silent route. Both TB selection modes pass the delayed-click fixture.
New key tests cover duplicate begins, processed holds, shared mouse controls,
case-insensitive multi-character keys and changed toggle modes. A 4 Hz config
watcher applies replacement/nested public-table edits atomically, rejects bad
updates without replacing the runtime, and preserves unrelated activation latches.

Core/runtime suites pass. Prediction/geometry/resolver work is still in progress;
this checkpoint is not the final FlowAuth upload. Production remains v1.3.21.
REAL is not exposed in the current tool inventory despite the owner's reconnection
message. No new game execution or native hit result is claimed.

---

# Current continuation: v1.3.21

Read BOX-PERSPECTIVE-WHITELIST-2026-10-24.md first. The user's screenshot clarified
that fixed pixel boxes were the wrong interpretation. Boxes now keep fixed
character-relative Width/Height and follow character perspective, without limb
fitting or size interpolation. Gun profiles still switch dimensions immediately
at configured physical range boundaries. Circle radii are unchanged.

Whitelist eligibility considers only online assigned users. The last assigned
departure restores normal eligibility for all three features. Saved IDs remain
available for rejoin; startup/apply with offline-only IDs cannot block everyone.

Source/protected suites and REAL static checks pass. The owner confirmed publishing
the v1.3.21 protected upload. Website PR #5 is merged (fb1b4c52fc9f2bc187c748116a159e9e8a5ffcd9),
Vercel reports success, and production /loader.lua matches the committed v1.3.21
bridge byte-for-byte: HTTP 200, text/plain, no-store. New live gameplay and actual
FlowAuth authorization remain unverified. Existing table values/keys remain.
Earlier live client became unresponsive; do not send more work to that old client.
Do not reload or alter the user's live runtime merely to inspect state.

Older publication notes and pixel-sizing assumptions below are historical.

---

# Current continuation: v1.3.20

See BOX-PERF-TB-REVIEW-2026-10-24.md for the live v1.3.19 capture and offline fixes.
The user now authorizes REAL inspection. Current client stopped responding;
do not send it more work until rejoin/re-injection. No live runtime reload occurred.
v1.3.20 source/protected tests pass. Owner confirmed publication to FlowAuth.
Website PR #4 is merged and production serves the exact v1.3.20 bridge (HTTP 200,
text/plain, no-store). New live runtime/FPS/TB checks remain pending; provider
authorization was not independently tested after the owner's publication.
Older instructions/publication notes below are historical, superseded here.

---

# 1.3.19 fixed dimensions and instant range changes - 2026-10-24

Current source is published on repair/neoperro-evidence. Protected uploads remain
outside Git in releases/neoperro-1.3.19. The website bridge expects v1.3.19; the
owner must still publish that runtime to FlowAuth. Older publication-pending
notes below are historical. No live Roblox verification was performed.

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

# Continue from 1.3.18

Use repair/neoperro-evidence and repository-root sources. Main and historical
snapshot/ZIP are older. Preserve local edits and the accepted table. Current user
instruction: **"dont inject js work"**. Do not execute, reload or alter Roblox until
the user explicitly authorizes live work again. Static analysis is not injection.

## Implemented and checked offline

- Assist rotates the actual cursor ray toward its point before Silent/TB select.
  This addresses an off-center cursor/camera-center mismatch. Shared bindings and
  feature gates stay independent. An eligible Silent point can supply a TB-owned
  shot; otherwise TB retains its own point. LastShotRoute exposes the distinction.
- Same-build/distribution starters apply table edits in place without HTTP,
  compilation or another provider launch. Invalid config is rejected before
  mutation. Owned input is released on valid edits; listeners/drawings/history are
  reused. Explicit config survives full-bundle defaults. Cold loads still auth.
- Empty Whitelist permits everyone in Friend/Target. All configured IDs survive;
  assignment has no cap. Membership lookup is cached and assignment changes
  invalidate it even when remove/add leaves the same list length.
- Internal posture detection samples geometry and actual game animation IDs.
  Generic track names are resolved through the game's catalog. Rotated parts use
  measured world height; pose transitions reset smoothing/prediction context.
- ESP DisplayName prefers Humanoid.DisplayName, preserving in-game tags.

Core/runtime suites and the complete protected-runtime suite pass. Full/runtime,
readable FlowAuth starter and protected upload pass REAL static analysis with zero
errors/warnings. Off-center tests cover TB FOV on/off, all eight feature switches,
shared hold/release and reverse-ray geometry. Mocks do not prove compatibility.

## Evidence boundaries and prior mistake

Intermediate native tests measured fast warm config updates without accumulating
listeners or drawings. Exact figures are in SESSION-2026-10-23.md. They are not
live verification of the final cursor fix or posture behavior. Actual provider
authentication/publication is untested. The prior launch_ticket_rejected console
message has no established cause. The user withdrew the crash investigation.

An intermediate test loaded defaults from a Downloads starter instead of the
user's edited table. The live runtime was later absent. The default E panic key
was observed, but its causal role in unload was not proven. We admitted this and
stopped live changes. Do not reuse stale wrappers or assume the starter is the
user's private config. Preserve their key/table and replace only the bottom loader.

## Release and remaining work

Protected release files live outside Git under releases/neoperro-1.3.17. Upload
neoperro-flowauth-upload.obfuscated.lua into the existing FlowAuth script, publish,
require keys and enable Auto-obfuscate with keyless disabled. The loader-only file
upgrades the user's private starter without replacing their key/table. Never
request, print, save or publish their real key or executor credentials.

The follow-up prediction/3D review is recorded in PREDICTION-REVIEW-2026-10-24.md.
1.3.15 adds predicted-part Closest Point, evidence-gated acute-turn/braking response,
direct direction transforms and consistent held-trigger shot routing. Table values
are unchanged. All regressions and four static artifacts pass; no live injection.
When live testing is newly authorized, inspect current diagnostics/console first.
Do not infer shots from sends alone: distinguish target eligibility, selected
part, raw/sampled velocity, final point, muzzle, MOUSE payload, ammo/activation and
observed damage. Prior native shots were inconclusive; no perfect-hit claim.

Still open: controlled remote jumping/falling/strafe/macro shots at high ping,
broad third-person weapon/obstacle cases, and published FlowAuth cold/warm timings.
No new live intro/audio, full combination or hit-rate result is claimed. Existing
aim restoration, native pellets, Macro Abuse, gun profiles and once-per-session
intro remain protected by regressions. No new webhook logging was added.


Latest Auto Y changes are in AUTO-Y-REVIEW-2026-10-24.md. Current grounding uses
current-footprint geometry, independently of the future landing surface and remote
FloorMaterial. Continuous plane support can follow low vertical motion on ramps.
A corrected TrueVelocity Y cannot use acceleration fitted from rejected raw Y.
The motion fit accepts a bounded sample-time velocity envelope (maximum 50 ms),
without adding history age to prediction. Stale models reject. All prior suites
and four REAL static artifacts pass; table values/Custom behavior remain unchanged.
No live injection occurred. Mixed-rate/replay results are mathematical fixtures,
not remote replication, moving-platform, server damage or FPS measurements.


## Latest airborne / 3D and Triggerbot pass (1.3.17)

Read AIRBORNE-TRIGGER-REVIEW-2026-10-24.md. The user reports airborne misses with
Auto, Custom and Y disabled, and failure with both Triggerbot FOV modes. Silent
is the main priority. New shared real-part fallback preserves fixed BasePart and
exact surfaces; native Closest Point uses predicted XYZ geometry in third person.
Only accepted points seed smoothing. Acceleration needs matching position evidence.
TB checks camera candidates completely before native fallback, and real body
height supplies Y bounds for native HB/accessory hits. These are offline source
findings/regressions, not a diagnosis proving every reported miss is fixed.

Current release: releases/neoperro-1.3.17 outside Git. Core/runtime/protected suites,
1,452-case idealized replay and all four REAL static artifacts pass. No table
values/names changed. No live injection, provider authentication or observed damage
was added. Preserve the user's real key/private table; replace only the old bottom
execution block with the release loader-only file after they publish the upload.

Still needed after explicit live authorization: remote ascent/apex/fall/landing,
diagonal macro motion, high-ping hit attribution, side/rear/elevated third-person
weapon/muzzle/obstacle cases, and populated-server performance. Record selected
part/point ray, CandidateAttempt, raw/sampled/resolved XYZ, vertical position/linear
fit residuals and confidence, applied acceleration, final point, muzzle, MOUSE
payload, native firing/ammo and observed damage separately. Model/sampler tests
are not real FPS, replication or hit-rate evidence. Do not inject under the current
instruction.


## Current 1.3.18: user explicitly requested no MCP

Read SILENT-PIXEL-MACRO-REVIEW-2026-10-24.md. Silent was prioritized before fixed
pixel boxes and Macro cleanup. No MCP tools, live interaction or REAL analyzer
were used. Full Core/runtime/protected mock suites and syntax checks pass. Preserve
this distinction from older static/live results. Shared checks still pass in mocks;
this is not proof that every feature is improved or live-compatible.

Release files are under releases/neoperro-1.3.18 outside Git. Keep box values
Width=5 / Height=4.3: 1 unit is 16 pixels at 1080p, scaled only by viewport height.
Distance and camera FOV never scale dimensions; gun profiles select size values
by weapon/range. Named gun fields are canonical; legacy pairs preserve numbers.
No old numerical size conversion is needed. BOX-UPDATE.md and raw
neoperro-protection/box-formula.lua explain the formula. Preserve private keys,
bindings, colors, switches and other preferences. Publish only the obfuscated
runtime to FlowAuth; loader/table stay readable. No real keys are needed.

Silent circle acquisition accepts actual or predicted points in the same radius;
configured AntiCurve, whitelist, KO/dead, exact-surface and foreground wall rules
remain. No fake gravity or upward constant was added. Macro late phases cancel
instead of replaying stale input; normal timing is unchanged. Real game lag,
server damage, 3D remote behavior, populated ESP timing and provider output still
need newly authorized testing. Do not use MCP or inject under the current request.

Latest shared review: expired Auto contexts cannot override fresh ping before
render refresh for Silent/Assist/TB. ESP cached visibility invalidates on camera/
target movement >0.5 world units, retaining its normal static 80ms cache. Removed
duplicate selection hold reads; all existing activation/combination checks pass.
Client bullets, aim restoration, Prefire, AntiAfk/AntiFling, whitelist, posture and
intro remain covered/preserved; no invented new algorithm is claimed for every
feature. No MCP or live results were added.


## Publication state after this pass

1.3.18 is built and committed locally, but Git CLI push could not authenticate.
The normal credential manager requested interactive login; a noninteractive retry
confirmed no usable Git CLI credentials. No MCP fallback or credential collection
was used. The remote repair branch still points to b45ba55 (1.3.17). Do not treat
its development loader/table as this release until publication succeeds. The local
full bundle and release's protected FlowAuth upload contain the actual 1.3.18 code.

After Git is authenticated, publish the reviewed local tree as a fast-forward
child of the remote head; do not force local divergent commit history over it.
Local and API-authored 1.3.17 commits have identical trees but different parents.
Publication message/SHA helpers are outside the repo under work/release18-*.
No user/customer key or executor credential is needed for these build artifacts.
