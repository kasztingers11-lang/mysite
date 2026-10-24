# v1.3.22 input, routing and shared prediction - 2026-10-25

## Priority repairs

A delayed native-input fixture reproduces the v1.3.21 TB/Silent failure: the
pre-click MOUSE point can be restored to normal aim before Tool.Activated arrives.
The old TB activation handler did not submit its routed point again. The repaired
handler resolves the current TB candidate and active Silent route at actual
activation, submits that fresh point, then restores ordinary aim. Native mouse
press/release remains the preferred path, matching Looten's input mechanism;
VirtualInputManager and Tool.Activate remain capability fallbacks. Both TB FOV
modes retain their independent selection/eligibility checks and TargetOnly rules.
The delayed-click test passes through the protected runtime as well.

Keys are normalized for case, whitespace and enum-style names. Duplicate begin
events no longer invert a toggle twice. Processed input cannot activate a held
feature through physical polling. Shared bindings still dispatch to each feature.
Changed toggle controls reset stale off-state; unrelated edits preserve toggles
and non-holding activation latches. Holding Target mode can acquire after startup
without requiring a new begin event. Assign/lock actions capture the view before
using geometry, including before the first render.

A bounded 4 Hz configuration observer handles replacement tables and nested edits.
ApplyConfig validates before mutation and reuses listeners, history and drawings.
A rejected edit leaves the running configuration active; correcting it in place
recovers. No provider request, rejoin, intro replay or runtime reload is required
for these same-session edits. The explicit ApplyConfig/loader path also remains.

## Shared prediction and geometry

Silent, Assist and TB share these changes in Auto and manual prediction:

- Signed XZ turn integration computes both forward and sideways displacement.
  Prior forecasts must beat straight-line forecasts against positions that actually
  arrived before a turn model is used. Turn-rate fitting uses sampled endpoints,
  so a faster render phase cannot inflate angular velocity. Vertical motion is
  evaluated independently, giving a full XYZ point rather than planar-only lead.
- Forecast residual covariance is measured against actual part CFrame axes and
  Size. A narrower or rotated torso can favor a different better-fitting motion
  model. Uniformly shrinking a target does not arbitrarily shorten a physically
  correct constant-motion forecast. Body tolerance also exposes uncertainty.
- Manual Value is calibrated at the feature's first valid RTT (or after its
  prediction settings change). Subsequent RTT differences adapt the effective
  horizon without rewriting Value. Unrelated table edits preserve calibration.
  Auto ignores Value and retains its half-second context refresh with live motion.
  RTT sources overlap and are not added together. No guessed projectile speed or
  tracer-duration-as-flight-time was introduced for the verified hitscan path.
- TrueVelocity can reject repeated alternating XYZ velocity when position history
  is coherent. Axis decisions remain independent, with teleport/reset handling and
  immediate fresh transitions. A replication freeze with constant raw speed alone
  is deliberately ambiguous, not proof of spoofing. No resolver can guarantee
  recovery of hidden server movement from client-only observations.
- The special fast-motion lead-time cap has been removed. Macro speed no longer
  receives an extra horizontal horizon restriction. Enabled AntiCurve evaluates
  the full final point using its configured units; disabled AntiCurve adds no
  macro-specific limit. Finite-data/teleport validation still applies.
- Auto Y no longer clips a valid airborne lead to the selected torso height.
  Coherent measured acceleration, apex handling, braking-stop and rig-derived
  support correction remain. Auto ignores Offset; Custom keeps its separate
  upward behavior. Ground checking corrects a predicted floor crossing rather
  than rejecting the whole candidate or adding a constant upward offset.
- Endmath measures muzzle-ray alignment on the plane at the predicted point's
  camera depth. It no longer rejects a forward aligned edge point solely because
  WorldToViewportPoint reports its center outside the viewport. Configured FOV,
  forward direction, pixel/stud limits and obstruction checks still apply.

2.2 studs for 3d-angles and 120 pixels for Endmath retain their units and defaults.
Existing Closest/Raycast/Part/Point/Axis/Reduce/Sharpness behavior now feeds the
shared forecast; exact surfaces, legal part bounds, point smoothing and fallback
checks remain under regression. No table names or values were changed.

## Checks and evidence limits

- Core/runtime and full protected-runtime mock suites pass, including delayed
  native TB activation in both selection modes; fresh routing; repeated clicks;
  processed/shared/held keys; changed controls; atomic live config edits; and
  cleanup/resource bounds.
- Analytic trajectory cases pass for signed turns and concurrent XYZ ballistic
  motion at 60/144/240 simulated render rates, plus all three feature forecasts
  in Auto/manual with normal and tiny torsos. This is numerical/mock evidence,
  not a measured Roblox frame rate or hit rate.
- Resolver cases cover persistent false vectors, alternating XYZ vectors, genuine
  fresh transitions, irregular position samples and teleport resets. Body-frame
  covariance tests cover anisotropic and rotated geometry.
- Existing whitelist departure/rejoin, gun profile/perspective box, ESP hidden-work,
  Macro, client-beam style/spread, feature combination and protection guard cases
  continue to pass.
- Official Luau 0.744 compiles the full bundle, runtime, starters and native/
  protected uploads. Its analyzer reports zero errors/warnings for pure core.lua.
  This is not REAL's Roblox/executor-aware type analysis.

REAL is not exposed in this turn's tool inventory despite the owner saying it was
reconnected. No new client diagnostics, game scripts, console, input, sends or
observed shot results were read/produced. Live Roblox compatibility, server shot
ordering, high-ping airborne hits, native focus behavior and actual FPS remain
unverified. Mocks and native source compilation do not prove those results.
The provider publication/authentication is not tested. Publish the new runtime
before switching the prepared website bridge from v1.3.21 to v1.3.22.
No customer key or executor credential was read, printed or placed in artifacts.

Primary API references: Roblox [UserInputService](https://create.roblox.com/docs/reference/engine/classes/UserInputService),
[Player.GetNetworkPing](https://create.roblox.com/docs/reference/engine/classes/Player#GetNetworkPing),
and [Camera](https://create.roblox.com/docs/reference/engine/classes/Camera).
Native compiler: official luau-lang/luau release 0.744, Windows archive SHA-256
fde3e22c557aac6afe20a34e8050b7d8c290fa42638c04274a307ed5d0ef0db8.
