# Silent prediction and 3D review - 2026-10-24 - 1.3.15

This was offline source, regression and static-analysis work. No Roblox injection,
input, live reload, server firing or damage observation occurred. The user kept
live work disabled. Version 1.3.14 was pushed before this follow-up review began.

## Changes supported by regressions

1. **Closest Point used current geometry before adding prediction.** A cursor ray
   through the translated predicted part could receive a point displaced away
   from that ray. The selected part's forecast is now computed first, then the ray
   is translated back by that XYZ offset before entering the rotated part's local
   frame. Reduce, Axis and Sharpness still operate inside actual part bounds.
   The final point adds the same lead. This refines the point inside the selected
   part; it does not claim exhaustive future-pose ranking of every limb.
2. **An acute turn or same-sign slowdown could retain an older validated fit.**
   The new guard compares a recent observed displacement segment with raw and
   fitted velocity independently in XZ and Y. A recent raw change must also fit
   that segment better before it overrides history. A changed raw value without
   supporting movement retains the validated fit. Reversals/jump onset and
   persistent coherent TrueVelocity corrections keep their existing behavior.
3. **Held Triggerbot could replace its accepted Silent route on the next frame.**
   Initial firing and owned-hold refresh now use one routing helper. Triggerbot
   keeps its activation/selection/click ownership; eligible Silent supplies the
   coordinates. If Silent becomes ineligible, TB falls back to its own accepted
   point. No extra packet, input owner or feature switch was added.
4. **Repeated support work was unnecessary for current hitscan weapons.** Point
   selection reuses its forecast instead of casting a second identical support
   ray. Ground-minimum/base-point diagnostics are rebased to the actual selected
   point. Ray directions use VectorToObjectSpace directly rather than subtracting
   two translated world points. This avoids adding position to a direction and
   removes one point transformation per local-ray calculation.

## Validation and provenance

The current Core/runtime suites pass. The entire runtime suite also passes against
this version's obfuscated payload with synthetic grant/hash primitives. Protection,
config, resource cleanup, native pellets, aim restoration and previous prediction
regressions remain passing. No test contacts FlowAuth or uses a customer key.

New coverage includes four XYZ movement cases, 18 combinations of feature x
manual/Auto x part orientation, 18 corresponding exact Raycast cases, actual part
bounds, one support query per accepted Point selection, landing-support diagnostic
rebasing, observed diagonal turn/braking and held-route fallback. The earlier
committed implementation fails the newly reproduced Closest Point, turn and held
routing cases; the revised implementation passes. The observed-turn regression
was also run explicitly against the prior committed Core to verify that failure.

The final runtime, full bundle and protected upload each pass REAL static analysis
with zero errors/warnings after the final source edit; the unchanged 1.3.15 starter
also passes. A temporary diagnostic-field type error found during this review was
fixed before packaging. These are analyzer results, not Roblox execution results.

Looten's snapshot was re-read around Silent XYZ prediction/Tool.Activated and its
Auto ping ladder. Its relevant XYZ/activation paths remain represented. Its first
`ping < 190` branch catches values meant for subsequent lower thresholds, and two
values read `1344`; copying that ladder would not provide a sound Auto predictor.
No reuse percentage is claimed. Current active estimates remain half-second
updates, with live motion response between updates. Verified hitscan behavior
continues to add zero flight time; no guessed bullet speed or upward offset.

Roblox documents [VectorToObjectSpace](https://create.roblox.com/docs/reference/engine/datatypes/CFrame/VectorToObjectSpace)
as a direction rotation without translation. Its [network diagnostics](https://create.roblox.com/docs/performance-optimization/identify)
distinguish network RTT and replication data RTT. These support the API/unit
interpretation; they do not establish this game's server compensation or hit rate.
A fresh attempt to open FlowAuth documentation returned 403; setup instructions
retain the previously inspected provider requirements and supplied public loader.

## Limits

No final live shot, moving remote player, macro, weapon/obstacle matrix or published
FlowAuth cold/warm timing is established by this review. Auto Y remains a bounded,
measured-motion/support model rather than perfect future-state knowledge. Sharp
unobserved movement cannot be known in advance. Closest-point refinement preserves
the current selected part and does not predict unobserved limb animation. The
executor documents getgenv view-identity quirks; native cross-chunk starter/session
reuse still needs validation after the user authorizes live testing. Explicit
configuration propagation and intermediate warm-update measurements are separate
from that pending published-build check. No crash cause or universal compatibility,
concealment, FPS, anti-aim recovery or hit guarantee is claimed.
