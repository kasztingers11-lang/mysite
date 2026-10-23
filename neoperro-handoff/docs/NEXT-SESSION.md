# Continue from 1.3.15

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

Protected release files live outside Git under releases/neoperro-1.3.15. Upload
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
