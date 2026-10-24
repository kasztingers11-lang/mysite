# Airborne Silent / third-person XYZ and Triggerbot - 2026-10-24 - 1.3.17

The user reports misses with Y-Axis Auto, Custom and disabled, and problems in both
Triggerbot FOV modes. Silent is the main priority. This pass changes authoritative
Core/runtime sources, regenerates development/protected outputs and runs offline
checks. The standing instruction is **dont inject js work**. No game execution,
input, executor credentials or real customer keys were used.

## Source findings and changes

1. Present-position nearest part selection could reject an entire target after
   that part's predicted point failed FOV/AntiCurve/wall checks. Closest can now
   retry another real body part before discarding the player, in existing
   cursor-distance order. Each candidate gets the same final checks. Fixed
   BasePart, exact cursor surfaces and eligibility failures do not switch parts.
   Box FOV membership is player-wide, so box rejection skips pointless part scans.
2. Silent Closest Point previously solved only the camera ray, although final
   AntiCurve already understood a native muzzle corridor. It now solves the same
   translated predicted part against both forward camera and muzzle-to-Mouse.Hit
   rays, preferring closer native alignment when appropriate in third person.
   The original ray can be retried if the preferred point fails final checks.
   Axis/Reduce still bound the real rotated part. This changes coordinates, not
   weapon physics, hitboxes, FOV limits or the server. Mandatory final muzzle
   obstruction and forward geometry rejection remain intact.
3. A rejected closest point previously seeded subsequent point smoothing. Only
   accepted points now update that state; changing camera/native point ray resets
   interpolation across incompatible references. Sharpness still uses frame time.
4. A smooth raw-Y slope could look like gravity even while observed positions
   stayed level. The fitted curve now needs at least two observed displacement
   comparisons, lower squared error than linear raw extrapolation, and bounded
   absolute position residual. Confidence/time bounds and existing Y lead clamps
   remain. No assumed gravity, bullet travel time or upward constant is added.
   Auto uses supported measured acceleration. Custom keeps its positive Offset
   multiplier; disabled keeps ordinary linear XYZ prediction with independent
   ground checks. Auto is not enabled behind either of those settings.
5. FOV-off TB could stop after finding a camera character that failed final
   eligibility/prediction, without trying an eligible native muzzle candidate.
   Each camera candidate is now checked completely before native fallback. This
   also preserves TargetOnly/whitelist/knocked/wall rules. A native HB/accessory
   surface retains exact selection coordinates; real UpperTorso/Torso supplies
   Y/rig bounds, so helper height cannot inflate or suppress vertical lead.
   FOV-on TB uses the shared real-part fallback. Native press/hold/release, shared
   Silent shot routing and independent activation are unchanged.
6. Removed Circle.NumSides writes, unsupported by Real's documented Drawing API.

The accepted configuration table is unchanged. Existing aim restoration, native
client pellet styling/spread, Macro Abuse, ESP, profiles, pose, whitelist, clean
replacement, intro and fast same-build table updates remain under regression.

## Offline evidence

- Core and full runtime suites pass on Lua 5.4 through Lupa.
- Nine feature x Y-method cases cover a nearest Head whose predicted point leaves
  the circle while the torso enters it. Fixed Head and exact Head surfaces remain
  rejected rather than silently switching. This covers FOV-on TB, Silent, Assist.
- Twelve Y/timing/left-right third-person cases retain a 0.001-stud AntiCurve limit,
  legal pre-lead body coordinates and final muzzle obstruction rejection.
- Thirty integrated cases combine five camera bases (front/rear/side/pitched/rolled),
  manual/Auto timing, Auto/Custom/disabled Y, coherent measured acceleration and
  XYZ translation. The mocked Tool.Activated MOUSE coordinates equal the accepted
  final point. This is client call evidence in a mock, not accepted server damage.
- Native TB regressions cover helper heights 1/40 with identical real-body forecast,
  plus an ineligible camera target and a separate valid offset-muzzle target.
- A raw gravity-like velocity ramp with flat observed Y produces no accepted
  acceleration model. Existing ideal ballistic/turn/braking/ground/pose tests pass.
- The independent analytical replay still passes all 1,452 forecast cases across
  30/60/144/240 schedules. It uses the same existing lead clamps. Its old comparison
  is 1.3.15 (sampling-phase issue fixed in 1.3.16); do not present that improvement
  as newly obtained in 1.3.17. Numerical residual is at most 3.6e-14 studs under
  exact idealized input. No physical FPS or remote accuracy follows from it.
- The entire runtime suite also passes against the actual obfuscated upload after
  the initial intro fixture, with synthetic grants/hash primitives. Guard and
  starter/config tests pass; no provider login. Four REAL static artifacts
  (full/runtime/starter/protected) each return zero errors and zero warnings.
  A local grant declaration is supplied for protected analysis only.

Diagnostics add CandidateAttempt, PointRay/PointRayOrigin/PointRayDirection,
SelectionRay/SelectionOrigin/SelectionDirection, SurfacePart and vertical measured
position/linear errors plus VerticalValidated. Existing selected part, velocity,
lead, camera/muzzle, final point and send/restore records remain separate.
Fallback scans occur only after rejection and only over real rig parts; accepted
first candidates do not add a full rig scan. Native point solving adds math, not
an extra common-path obstruction query. No populated-server benchmark was run.

## Still uncertain

These code defects and passing mocks do not establish the cause of every reported
miss or prove Roblox compatibility. Actual remote latency/interpolation, abrupt
movement, unavailable streamed geometry, server validation/damage, weapon variants
and blocked third-person firing need newly authorized controlled live tests.
Moving/rotating platforms and noisy/asynchronous positions may conservatively
reject acceleration; the fit does not know unobserved future input. No perfect
prediction, all-shots, universal concealment or 240-FPS guarantee is made.

Upload only the release's neoperro-flowauth-upload.obfuscated.lua to the existing
FlowAuth script and publish. Keep the private key and edited table; replace only
the old bottom execution block with neoperro-flowauth-loader.lua. Protected release
files stay outside the public Git repository. Actual published output and cold
provider timings remain untested. Do not inject without new user authorization.
