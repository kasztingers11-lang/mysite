# 1.3.20 render work and TB/Silent cooperation - 2026-10-24

## Observed live before this revision

The connected client loaded FlowAuth v1.3.19 and its ProtectedBuild matched the
local release metadata. Gun Specifications was false, Silent Width=6/Height=5.5.
A 30-second read-only job sampled 290 times. One native Drawing rectangle stayed
96x88 pixels throughout a 3.059-187.628 stud distance span; it was visible in 131
samples. This is native Size evidence, not a successful near/far screenshot
comparison. The later screenshot was white and cannot establish visual behavior.
No runtime reload, setting edit, injected render loop or input simulation occurred.

The capture contained only an ESP-on phase: approximately 150.44 render callbacks
per second, 2.731 ms aim calculation per frame and 0.461 ms drawing work per frame.
No valid ESP-off comparison was captured. Do not attribute the user's entire
250-to-200/100 FPS report to these measurements or promise a particular FPS.
Later REAL eval and its health probe stopped receiving client replies. Its cause
is unknown. Live calls stopped; rejoin and re-injection are needed before more work.

## Source changes and checks

- Box-mode candidate rejection happens before per-body-part searches. Circle
  prediction acquisition, Silent Ignore and assignment remain independent.
- Hidden ESP hides once and then skips player eligibility/visibility/drawing work.
  Hidden FOV circles no longer rebuild or write properties each frame.
- TB can use the active eligible Silent point after its own otherwise-unused
  prediction is rejected. Both FOV modes retain TB activation, actual cursor/shape,
  independent eligibility and wall checks. A missing body hit with FOV off cannot
  be supplied merely by Silent's selected player.
- Fixed Width*16 / Height*16 dimensions and discrete gun profile boundaries remain.
  No new box formula or interpolation is claimed: native v1.3.19 dimensions were
  already constant in the live capture. User-perceived resizing remains unexplained.

Core/runtime and full protected-runtime suites pass. New regressions cover
bounded root-only projection work outside boxes, zero repeated hidden visual
writes, visibility restoration, and a TB predicted-wall rejection with an eligible
Silent point in both FOV modes. Actual-body and independent knocked checks remain.
All configuration values and names remain unchanged. No live result for v1.3.20
or provider publication is claimed. Source edits and protected artifacts alone do
not prove a live FPS improvement or that the perceived sizing issue is resolved.


REAL static checks also pass with zero errors/warnings for the full v1.3.20 bundle.
The protected upload passes with a static-only local declaration for FlowAuth's
LRM_IsUserPremium variable, supplied from varargs; that declaration is not written
into the release file and supplies no real authorization. Initial checker findings
identified the missing ESPHidden state declaration (fixed in the runtime) and the
provider global absent from REAL's standalone definitions (modeled only for checking).
