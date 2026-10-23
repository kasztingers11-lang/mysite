# neoperro 1.3.14 settings and development

Edit the table in neoperro.lua, then execute the entire file. The loader at its
bottom fetches this repair branch. neoperro-full.lua is the equivalent bundle
used for live testing when authorized. The starter applies table edits directly
to an alive runtime of the same version and distribution. This avoids another
download, compile and provider launch. New builds or stopped runtimes load normally.
Valid toggles, locks and whitelist state survive unchanged initial settings.
Explicit configuration passed to a bundle takes priority over its default table.

## Controls and activation

| Default | Action |
| --- | --- |
| P | Silent Aim toggle |
| T | Silent target selection in Target mode |
| M | Aim Assist toggle |
| Hold Q | Aim Assist |
| V | Triggerbot arm/disarm |
| Hold RMB | Triggerbot activation |
| Z | ESP toggle |
| R | Whitelist assignment when enabled; overlaps game reload |
| Hold C | Prefire when enabled |
| E | Panic/unload when enabled |

Keybind tuples are {keyboard key, mouse button, device}. Only the third entry
chooses the device. Shared bindings operate independently; Panic takes priority.
Enabled=false disables a feature regardless of retained toggle state. Focus loss,
text entry and the Roblox menu suppress automation and release owned input.

Camera Assist aligns the actual cursor ray, including off-center cursors, before
Silent and Triggerbot perform frame selection. Triggerbot keeps ownership of its
click and its independent eligibility checks; an eligible active Silent point can
supply the shot coordinates. Without one, Triggerbot uses its own accepted point.
Diagnose().LastShotRoute separates click source, aim feature and selected players.

Silent Aim and Aim Assist use Activation. In Auto, Holding=true requires that
input; false searches continuously. In Target, Activation selects/holds the lock.
Triggerbot has its own Activation.Enabled and Holding gates. Physical hold state
is recovered after execution or a missed input event. InputStatus() reports
disabled, toggle-off, toggle-not-held, activation-not-held/off and focus states.
Legacy Keybind Mode and Work With TB names migrate when the new names are absent.

## Settings

| Section | Behavior |
| --- | --- |
| Prediction | Separate Enabled, Auto and Value in all three features. Active target/weapon/ping estimates refresh every 0.5 seconds, immediately on target/weapon changes; velocity response stays fast. Auto ignores Value and uses the larger overlapping RTT estimate, not their sum. Manual Value remains its baseline. Bounded horizontal speed response is always on; no Dynamic switch. |
| Resolver | The global Resolver exposes Enabled only for all three prediction features. TrueVelocity compares coherent sampled XYZ displacement with a persistent replicated-velocity mismatch. It requires at least four samples, 50 ms of evidence, stable reported components and a recent slope consistent with the fit. New direction changes remain immediate. Short/noisy/teleported histories fall back to the existing adaptive estimate. Disabled uses bounded raw velocity. No universal anti-aim guarantee. |
| Movement | Every prediction path bounds fast horizontal lead. Turn shortening requires recent forecast evidence; it does not add sideways acceleration. Stable measured vertical slopes can compensate jump acceleration. Internal crouch/prone/emote sampling uses rig geometry and game animation IDs; rotated parts use actual world height. Pose changes reset smoothing and active estimates. No projectile speed is invented for hitscan. |
| Closest | Part compares part centers. Point compares allowed part geometry against the forward cursor ray. Center permits local Y; All permits XYZ. Reduce=0 permits edges; 1 collapses to center. Sharpness is frame-time aware and clamped within the selected part. |
| Closest.Raycast | A real character/accessory surface under the cursor bypasses Reduce and Sharpness before prediction. Otherwise Part/Point behavior applies. Tool surfaces are excluded. |
| Y-Axis | Shared Enabled plus SilentAim, Aim Assist and Triggerbot switches. Method=Auto ignores Offset and uses measured vertical motion/support. Custom scales positive vertical lead with Offset. Basic XYZ prediction remains when this extra adjustment is off. Checks.GroundShotCheck has independent Silent/Assist/TB columns. |
| AntiCurve | Evaluates the final predicted point against camera and native muzzle-to-Mouse.Hit corridors. 3d-angles Max remains studs (2.2 default); Endmath Radius remains pixels (120). It rejects rather than clamps. Max/Radius accept 0.000000001 and larger numbers, including math.huge for unlimited distance/radius. Invalid forward geometry and muzzle obstruction still reject eligible firing paths. |
| Checks | Columns are Silent Aim, Aim Assist, Triggerbot. Wall checks use the firing muzzle for Silent/TB and the camera for Assist. Silent final wall checks are internal and always active; they do not control independent features. The removed EndMath block is ignored. |
| Triggerbot | Fov.Enabled=false requires a real ray hit or scaled native body/HB bounds; Character=1 is native, 1.2 is 20% larger, 0.8 smaller. Selection is local only. Camera and native muzzle rays support third-person parallax without bypassing intervening walls. Fov.Enabled=true uses the chosen circle/box. |
| Triggerbot timing | Acquisition presses immediately. Delay/RandomDelay sets button hold duration. SmartDelay uses Delay + min(distance/2000, 0.15) seconds as the hold duration, not a reaction delay. Owned cycles cancel on activation/target/weapon loss. |
| Gun Specifications | Enable and equip a supported gun. Profiles override Silent box Width/Height at configured Close/Medium/Far upper bounds, including standalone ESP. Beyond Far/unlisted weapons use general dimensions. Aim Assist and Triggerbot keep their own boxes. |
| 2d-Box / ESP | Root-centered world dimensions remain static under limb animation. Selection, Triggerbot checks, camera assistance, projection and FOV circles follow each render frame; no script FPS cap. History sampling remains paced separately and active estimates refresh every half second. Subpixel coordinates, property caching and reused visuals reduce stepping and property writes. DisplayName prefers Humanoid.DisplayName so game tags remain visible. Visible boxes remain on the actual character. Filled and transparency controls are removed; outlines stay unfilled and fully opaque. ESP and box distance are unlimited internally. Shot prediction remains active independently. |
| Whitelist | Empty lists allow everyone. After an assignment, Friend excludes assigned IDs; Target includes only them. Clearing the last assignment allows everyone again. No assignment cap. Disabled clears assignments/markers. Enabled assignments color ESP. Knocked/dead checks hide eligible boxes and labels. |
| Client Bullets | Rotates recognized native pellet endpoints toward ordinary mouse aim on this client. Native spread, color, width, texture and lifetime remain unchanged. Server shot coordinates stay separate. No substitute white beam or Mouse.Hit hook. |
| Anti-AimViewer | Continuous ordinary MOUSE updates pass through. Explicit predicted shot coordinates receive a deferred ordinary-aim restoration. The user-confirmed path is preserved; no universal concealment claim. |
| Macro Abuse | Strict Enabled gate. Macro Check matches the observed game Head horizontal speed >30 condition with a 120 ms pre-shot buffer. No Macro Abuse ammo option or I/O/wheel heuristic. Triggerbot check permits Triggerbot-originated cycles. Owned Ctrl/tool cleanup remains bounded. |
| Misc / intro | Prefire observes eligible opponent ammo decreases when active. AntiAfk and AntiFling keep existing behavior. The small animated cat, blur and original dark meow run once per client session, without intro settings or tinted backdrop. |

## Evidence and limits

See the session log for actual live results. Latest Q/RMB/profile/render and
parallax checks used temporary local fixtures with firing disabled, not another
Roblox player. One local native jump supports the measured vertical model but
does not calibrate remote replication, server acceptance or 200 ms combat.
Turn replay slightly increased mean error while reducing the 120 ms tail;
it is a conservative guard, not proof of generally better prediction.
Earlier airborne shots had mixed damage results. Full and runtime bundles now pass REAL analysis with zero errors/warnings.

No FPS or hit-rate guarantee is made. The separate FlowAuth upload includes a
provider-grant gate and payload integrity check; it cannot prevent a client owner
from reversing the code. No webhook logging is included. Final 1.3.14 collision
and posture behavior passes mocks/static analysis but has not been tested live.

## Source hierarchy and validation

- neoperro.lua: editable table and repair-branch loader.
- neoperro-config.lua: authoritative table.
- neoperro-src/core.lua, posture.lua, runtime.lua and loader-tail.lua: authoritative logic; defaults.lua is generated.
- neoperro-flowauth.lua: readable key/table/provider starter; protected releases stay outside Git.
- neoperro-intro/preview.lua and assets: intro.
- neoperro-full.lua and neoperro-runtime.lua: generated bundles.
- tests/: deterministic Core and Roblox-mock regression suites.
- neoperro-handoff/: references, screenshots and evidence. Snapshot/ZIP are historical.

Build: python build-neoperro.py.
Check: python tests/run-lua.py tests/core.spec.lua tests/runtime.spec.lua.
The tests require Lua 5.4 or Lupa's lua54 backend. Mock results do not prove Roblox
compatibility. Runtime Diagnose(), InputStatus() and bounded StartTrace()/ReadTrace()
separate target/part, raw/sampled/resolved velocity, lead, muzzle, final coordinates,
MOUSE sends/restores and shot-result uncertainty. Never save executor credentials.

The EndMath point visualizer and its Drawing allocation are removed. AntiCurve mode
and radius block are named Endmath; startup migrates older endmath tables.
The global Resolver uses TrueVelocity internally and exposes no Method selector. History
sampling remains active even when the resolver is disabled.

Canonical settings use Method for former Mode fields, Selection for Closest
Part/Point, Unlock Method and DelayMethod. Startup migration accepts older
names; canonical names take precedence. Removed visual/distance options and
Assist Ignore are stripped from old input and ignored during runtime use.
Global Anti-AimViewer and Client Bullets cover the shared Manual/Triggerbot/
Prefire shot pipeline; they do not create an additional firing feature.
