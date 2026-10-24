# Silent acquisition, screen-size boxes, Macro cleanup - 1.3.18 - 2026-10-24

User priorities: less restrictive Silent first, then a box formula without distance
scaling; distance belongs in Gun Specifications. Also improve intermittent Macro
lag. This entire pass uses local source/build/test/shell tools. No MCP, REAL static
analysis, Roblox input/execution or credentials were used. Earlier 1.3.17 REAL
results are historical and do not apply to these newly changed artifacts.

## Silent first

- Circle acquisition accepts either the real selected point or its forward
  predicted point inside the SAME configured radius. This removes rejection of
  an already acquired character merely because normal lead lies outside it.
  FovReference distinguishes base-point, predicted-point, box or Ignore. Final
  AntiCurve remains a separate hard limit with the same units and values.
- A present-position center just outside the viewport no longer prevents a final
  visible forecast from being checked. This shared fix covers Silent/Assist/TB.
  Whitelist assignment keeps its existing visible/150-pixel behavior.
- Exact Silent Raycast can use the first native muzzle-ray character surface when
  the camera ray misses that character. The real surface remains exact before
  prediction; it cannot be replaced by an alternate part after rejection.
- When a smoothed point fails final geometry, the fresh allowed point can be
  retried. Axis/Reduce, chosen part and final FOV/AntiCurve/wall checks still apply.
  SmoothingBypassed records the recovery; ordinary valid smoothing is unchanged.
- Final muzzle visibility accepts a first hit on the target itself. Excluding the
  target and then detecting cover behind it used to reject such a path. Foreground
  cover still rejects. Reuse one visibility result for ordinary/Endmath/mandatory
  wall checks instead of querying the same ray repeatedly. In the dedicated mock,
  accepted Endmath selection needs one cursor query plus one muzzle query.

No configured AntiCurve threshold, dead/knocked/whitelist gate, fixed BasePart,
manual/Auto prediction semantics or exact-surface contract was weakened. These
source defects and mock outcomes do not prove every airborne miss is resolved.

## Fixed pixel box formula and profiles

Keep Width=5 / Height=4.3. Pixel scale is 16 * viewportHeight / 1080, applied
to both dimensions. At 1080p these are 80 x 68.8 pixels. The final rectangle is
centerX - pixelWidth/2, centerY - pixelHeight/2. Distance and camera FOV do not
enter its dimensions. Only viewport resolution scales them. Positive camera depth
is required; the projected root supplies its center. General/standalone ESP use
the same sizes with no hidden fallback size. Raw box-formula.lua shows exact math.

Gun Specifications use BoxSize={Height=..., Width=...} with the previous numerical
values, such as 5.1/5.5/5. Physical distance chooses Close/Medium/Far using the
existing upper bounds. Unknown weapons, disabled profiles and distance beyond Far
use general dimensions. All configured guns and boundary transitions are covered;
ESP and selection share the formula. Assist/TB keep independent general values.
Legacy pairs map first=Width, second=Height. No guessed size conversion is needed.
Only box field names/order changed in the accepted table; the previous numerical
dimensions, keys, controls, colors, feature switches and prediction remain.

## Macro and other feature checks

Macro's working Head horizontal speed >30 test and 120ms pre-shot buffer remain.
No ammo/I/O/wheel gate was introduced. Normal .04/.06/.07/.07 phase timing remains.
A phase over 150ms late or a total cycle reaching 450ms cancels on the next update,
so long frames do not replay stale unequip/Ctrl actions. Cancellation releases
owned Ctrl and attempts tool restoration; it never releases an already user-held
Ctrl. Tool unequip/equip failures are caught and cancel rather than throwing every
frame. Diagnose().MacroCycle exposes phase/result/duration/restoration.

This addresses bounded-cycle/error behavior in source; the user's actual lag was
not captured and its live cause is unproven. No normal firing cadence was sped up
without live evidence. Shared feature gates, eight feature combinations, owned
input release, same-build updates, whitelist, posture, display tags, client pellets,
aim restoration and once-per-session intro remain passing in full regressions.
The shared review also fixes expired Auto ping contexts: all three forecasts use
fresh network values after cache expiry even before the render refresh runs. The
existing half-second cadence is retained. ESP visibility caches invalidate after
camera/target movement over 0.5 world units, instead of retaining a stale ray for
80ms. Static queries retain the existing cadence and are reused across visual
layers. Duplicate hold reads in selection were removed while activation remains
independent. Dedicated tests cover all-feature context expiry and both visibility
movements. There is no claim every feature received a new algorithm or is flawless.

## Validation and limits

Core/runtime suites pass with Lua 5.4 via Lupa. The same full runtime suite passes
against the rebuilt obfuscated upload after its intro fixture, using synthetic
grants/hash primitives. Guard, starter equality, key-placeholder and session-reuse
checks pass. New runtime cases reproduce the prior circle rejection and verify
viewport edges, exact native surfaces, fresh smoothing recovery, first-hit cover,
box visual/selection consistency, range boundaries, distance/FOV-independent dimensions and display resolution scaling, configured gun aliases, stalls and rejected tool actions. Build output
syntax and protected integrity/package digests are checked locally.

No MCP analyzer or game test was run. These are not Luau semantic, Roblox/native
input, remote hit-rate, measured FPS or published FlowAuth results. Controlled
high-ping air/strafe/macro targets, obstacles and all weapon effects remain open.
Upload only the obfuscated runtime, preserve the private key/settings, retain the existing numerical box dimensions and replace the bottom loader block. No webhook or extra
obfuscation feature was added in this pass.
