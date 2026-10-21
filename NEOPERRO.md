# neoperro 1.2.0

Cloud regression checks pass; live Roblox behavior remains unverified. See [repair evidence and in-game checklist](neoperro-handoff/docs/REPAIR-LOG.md). The handoff records the original broken build.

Open `neoperro.lua`, edit the commented table, and execute the entire file. The last line downloads `neoperro-runtime.lua` from this repository. The runtime never replaces your table with its defaults. Execute it again after changing the table to replace the active instance.

`neoperro-full.lua` contains the same table, runtime and intro in one file. The logo and audio still use the existing local asset cache. The three supported place IDs stay inside the runtime.

## Controls

| Input | Default action |
| --- | --- |
| P | Enable/disable Silent Aim |
| T | Select/reselect Silent Aim target in Target mode |
| M | Enable/disable Aim Assist |
| Hold Q | Aim Assist Auto: keep searching for the nearest eligible target |
| V | Arm/disarm Triggerbot |
| Hold right mouse | Triggerbot activation |
| Z | Enable/disable ESP |
| R | Add/remove the nearest player from the whitelist |
| Hold C | Prefire, when enabled |
| E | Panic/unload, when Panic.Enabled is true |

Each tuple has a keyboard key, mouse button, and the active device. For Triggerbot on Q, change its Activation.Keybind's third value from `Mouse` to `Keyboard`. Q can activate both Aim Assist and Triggerbot. All matching bindings dispatch; enabled Panic takes priority. Typing and GUI input suppress actions.

## Changes from 1.0

- Player boxes replace the old cursor rectangle. A box stays centered on each character root with the configured Width/Height in studs. Limb animation does not resize it. Its screen size changes with distance. The same geometry is used for selection, drawing and weapon profiles.
- Circles stay centered on the crosshair and use a radius in pixels.
- Target.Closest chooses the nearest body part. Center/All now controls point movement inside that body part. It no longer preserves an incorrect manual X/Z coordinate in Silent Aim.
- Firing follows Looten more closely: native mouse input is preferred for Triggerbot, with VirtualInputManager and Tool.Activate fallbacks. Fresh aiming coordinates are sent on click and Tool.Activated. Existing `MAINEVENT:FireServer('MOUSE', Vector3)` calls are scoped to the selected remote.
- Macro Abuse requires its strict Enabled flag. It can wait for a confirmed Ammo decrease and require movement plus a recently detected zoom macro. Normal walking speed alone cannot activate it. Disabling the live config cancels an active cycle.
- Assigned friends are green and assigned targets are red on ESP. These markers display even when whitelist targeting restrictions are disabled. AssignKey is the only whitelist key; set Mode in the table.
- Panic has an Enabled switch. The intro plays once per client session, including across re-executions. Upgrading an active older runtime also recognizes that its intro already ran.

## Settings

| Section | Behavior |
| --- | --- |
| Silent Aim | Auto acquires candidates without a target selection key. Target uses its selection input. Ignore bypasses circle/box boundaries; other checks still apply. The feature's Enabled flag and toggle still control it. |
| Aim Assist | Auto searches continuously while the configured hold input is down. Setting Holding false makes Auto continuously active. Target retains explicit player selection. Camera smoothing is adjusted for elapsed time. |
| Target | BasePart selects the part when Closest is off. Closest.Enabled chooses the body part nearest the crosshair. Method Part aims at its center; Point uses a reduced point inside it. |
| Closest.Raycast | Uses the actual character surface under the cursor before prediction. It bypasses Reduce and Sharpness for that hit. Otherwise the chosen Part/Point method applies. |
| Closest.Axis / Reduce | Center moves the local point along Y; All permits XYZ. The corresponding Reduce entry controls distance from the edges: 0 permits edges, 1 collapses to the part center. |
| Closest.Sharpness | Smooths local point changes in Point mode: 1 responds immediately, 0.01 responds slowly. Part changes reset this local filter. |
| 2d-Box | Separate Silent Aim, Aim Assist and Triggerbot styles. Size is world Width/Height; visibility, predicted position, distance, name type, foreground/outline colors, fill and opacity are configurable. Hiding a box does not disable its selection boundary. |
| Checks | Independent Silent Aim / Aim Assist / Triggerbot columns for health, knocked state, walls, ForceField, crew and equipped weapon. ESP.DeadCheck or that feature's Dead check hides its dead-player box and label. |
| Y-Axis | Auto ignores JumpOffset and uses a bounded airborne gravity adjustment. Custom scales positive vertical velocity by JumpOffset. Separate SilentAim/AimAssist flags select where it applies. |
| Prediction / EndMath | Lead times are seconds: 0.128 Silent, 0.121 Assist/Trigger. EndMath is nested under Silent Aim; its final checks never gate the other features. History resets after discontinuities. |
| AntiCurve: 3d-angles | Rejects when final point is farther than Max studs from ordinary Mouse.Hit. User-confirmed units; disabled by default. |
| AntiCurve: endmath | Rejects projected points outside Radius pixels around the cursor; never clamps prediction. Optional final wall check originates at the muzzle. Disabled by default. |
| Whitelist | Up to four unique UserIds. Friend excludes those IDs from targeting; Target allows only those IDs, when Enabled. AssignKey adds/removes the closest on-screen player within 150 pixels. Disabled clears assignments and markers, including across replacement. |
| Triggerbot | Enabled plus the toggle arms it. Activation optionally requires a hold/toggle input. Fov.Enabled false requires an actual character under the cursor ray; true permits the selected circle or player-box boundary. Delay/RandomDelay/SmartDelay select button hold duration, matching Looten; acquisition presses immediately. One owned cycle is cancelled on activation/target loss. TargetOnly requires the Silent Aim target. |
| Gun Specifications | Normalizes Looten weapon names internally, selects the distance range, and replaces the corresponding player-box dimensions. No per-gun prediction fields. Unlisted weapons and targets beyond Far use the general box size. |
| Client Bullets | During firing, compatible mouse hooks use the selected point. Recognized local gun/bullet/tracer Beams also receive temporary endpoint redirection. Without a selected point, ordinary mouse behavior applies. Custom Trail/projectile implementations are not universally covered. |
| ESP | Reuses Drawing objects, with native GUI fallback. Boxes follow the character root rather than animated body bounds. Hidden Silent boxes leave independent 6x6 ESP; visible Silent styles override it. Configurable visibility and distance checks still apply. Whitelist markers override the box/name foreground color. |
| Macro Abuse | After an eligible shot: unequip, hold Ctrl, equip, release. Check Ammo waits for an observed decrease. Macro Check requires movement and repeated alternating I/O or wheel inputs within a recent window, based on Looten's macro inputs. External macros that do not expose those inputs cannot be reliably recognized. Work With TB controls Triggerbot shots. |
| Misc | AntiAfk uses supported VirtualUser input. AntiFling mitigates a severe linear/angular velocity spike. Prefire reacts to replicated opponent Ammo decreases while held. Panic cancels pending work, releases owned input, restores an unequipped macro tool when appropriate, and removes visuals. |

## Lifecycle and limitations

One event/render set belongs to the active runtime. Re-execution disconnects the old subscriptions and render binding, cancels shots/macros, releases owned mouse/Ctrl input, and removes old visuals. Valid target IDs, whitelist assignments and toggles persist unless their original config values changed. Held activation states reset. Hook dispatchers are reused and pass through after unload.

The Anti-AimViewer option confines redirection to firing windows and leaves idle mouse updates alone. It does not guarantee concealment from spectators or administrators. AntiCurve filters also cannot change the server's projectile implementation or guarantee hit registration. The actual muzzle attachment is preferred when present, with Handle/root fallback.

Target selection and velocity sampling run at 30 Hz. Camera interpolation and visual projection run at render rate. No FPS cap is imposed. Source size is determined by the implemented features; it is not padded to a target line count.

Live Roblox execution is unavailable here. Shot acceptance, native input permissions, and server/client timing still require an in-game test. The source reference establishes the remote layout, not that every current executor implements it successfully.

For troubleshooting:

```lua
local runtime = getgenv().__neoperroRuntimeV1
if runtime then
    print('Version:', runtime.Version)
    for key, value in pairs(runtime.Capabilities) do print(key, value) end
    for key, value in pairs(runtime.Stats) do print(key, value) end
    for key, message in pairs(runtime.Warnings) do warn(key, message) end
end
```

## Validation and sources

Build with `python build-neoperro.py`. Run `python tests/run-lua.py tests/core.spec.lua tests/runtime.spec.lua`. The runner syntax-checks the generated loader/full/runtime files and executes deterministic Lua math and Roblox mock checks. These are not live engine tests.

Checks include player-box versus circle selection, weapon box overrides, exact cursor-surface targeting, stable ESP dimensions, friend/target colors, dead-player visibility, hold-to-search retargeting, native input firing when Tool.Activate is insufficient, delayed-shot cancellation, shared activation keys, disabled macro behavior, walking versus macro detection, ammo confirmation, disabling a running macro, optional Panic, one-time intro, filters, respawn, GUI fallback and cleanup.

- [Looten](https://github.com/kasztingers11-lang/mysite/blob/main/Looten): `MAINEVENT/MOUSE`, Vector3 payload, Tool.Activated, mouse1press/mouse1release, I/O macro inputs, knocked/crew paths, and weapon names. Its AntiCurve and Anti-AimViewer switches do not contain algorithms to copy. The source was read, not executed.
- [Goodnight config](https://github.com/kasztingers11-lang/mysite/blob/main/gn): configuration structure; its remote loader was not executed.
- [Roblox Tool documentation](https://create.roblox.com/docs/reference/engine/classes/Tool) and [activation input documentation](https://create.roblox.com/docs/reference/engine/classes/ContextActionService/BindActivate): input-driven activation and Tool.Activate are separate integration paths worth checking for a gun controller.
- [DevForum gun aiming discussion](https://devforum.roblox.com/t/how-would-i-go-about-making-a-gun-system-like-this/1794916): camera-to-cursor ray followed by a muzzle-to-hit-point ray. This supports the origin/visibility checks, not a guaranteed anti-curve algorithm.
- [DevForum third-person aiming discussion](https://devforum.roblox.com/t/ray-does-not-hit-where-the-mouse-is-in-third-person/2803154?page=2): camera/muzzle separation matters in third person.
- [Roblox camera documentation](https://create.roblox.com/docs/reference/engine/classes/Camera) and [raycasting guide](https://create.roblox.com/docs/workspace/raycasting): viewport projection and filtered world queries.
- [Frame-rate-independent damping derivation](https://www.rorydriscoll.com/2016/03/07/frame-rate-independent-damping-using-lerp/) and [DevForum discussion](https://devforum.roblox.com/t/frame-rate-independent-lerp/352375/18): exponential smoothing instead of fixed per-frame lerp strength.
- [sUNC hooks](https://docs.sunc.io/Closures/hookmetamethod/) and [namecall method](https://docs.sunc.io/Metatable/getnamecallmethod/): executor contracts, separate from Roblox's supported game scripting APIs.
