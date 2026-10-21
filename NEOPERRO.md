# neoperro 1.0.0

`neoperro.lua` is the complete editable script: configuration first, runtime and intro below it. Execute the whole file. Change the table and execute it again to replace the running copy. `neoperro-runtime.lua` is the same runtime without a public configuration assignment, ready for a separate loader later.

The three place IDs are internal: Da Strike `134196333708867`, Da Uphill `71324444457408`, and Da Downhill `139144803593140`. They use the same adapter, based on the user's confirmation that these are new IDs for the same games.

## Controls

| Input | Default action |
| --- | --- |
| P | Toggle Silent Aim |
| T | Select/reselect Silent Aim target when its Mode is Target |
| M | Toggle Aim Assist |
| Q | Lock/unlock Aim Assist target |
| Hold V | Triggerbot |
| Z | Toggle ESP |
| R | Add/remove the player nearest the cursor from the whitelist |
| F | Clear whitelist |
| B | Switch whitelist Friend/Target mode |
| Hold C | Prefire, when enabled |
| E | Panic: unload and release script-owned inputs |

Shared keys dispatch every matching action. Panic wins when its key is shared. Typing and processed GUI input do not activate bindings. Losing focus releases hold actions and cancels pending shots and the macro.

## What each section does

| Section | Runtime behavior |
| --- | --- |
| Anti-AimViewer | A scoped namecall hook replaces idle `MAINEVENT/MOUSE` coordinates with camera-forward coordinates. Clicks and tool activations open a 120 ms shot window; holding the left mouse button also permits shooting coordinates. This is a local timing approximation, not an exact server network tick or a concealment guarantee. |
| Y-Axis | Custom scales positive vertical velocity by JumpOffset. Auto ignores JumpOffset, applies a gravity-based airborne adjustment with a body-size bound, and removes vertical lead when grounded. Separate switches choose Silent Aim or Aim Assist. |
| Checks | Each row independently controls the three targeting features. Uses Humanoid health, `BodyEffects.K.O`, supported knocked attributes, ForceField, visibility rays, `DataFolder.Information.Crew`, and equipped weapon checks. |
| Silent Aim | Auto chooses the nearest eligible projected target. Target mode uses the chosen key and retains the selected player while temporarily invalid targets are suppressed. Ignore bypasses the FOV/profile bounds, while the other checks remain active. |
| Aim Assist | Rotates the camera after Roblox's camera update. Smoothness is interpreted as a 60 FPS reference and converted using `1 - (1 - strength)^(60 * dt)`. Camera position is preserved. |
| Part / Point / Axis | Part uses the part center. Point projects the cursor ray to the part's depth and clamps it inside reduced oriented bounds. Center keeps the user's horizontal direction and changes vertical aim; All uses XYZ. R6 Torso is a fallback for UpperTorso. |
| FOV | Box and circle use the same viewport coordinates as mouse targeting. Sizes are pixels; circle size is radius and box X/Y are full dimensions. Hiding an outline leaves its selection boundary active. |
| AntiCurve | `3d-angles` limits the angular difference between direct and predicted aim. `endmath` caps final displacement from the original body point by Radius. These are bounded filters, not a desync resolver or a projectile-curve cancellation system. |
| Prediction | The three values are lead times in seconds. Velocity is multiplied by the selected lead once; ping is not multiplied in again. |
| EndMath | Fits velocity to a bounded timestamp history and resets the history after large discontinuities. WallCheck tests the final position from both camera and weapon origin. Visualizer shows final aim points. Replicated positions still contain latency. |
| Whitelist | Friend excludes assigned UserIds; Target permits only those IDs. Holds at most four unique IDs. Assignment uses the closest on-screen player within 150 pixels, so a previously excluded player can be removed. |
| Triggerbot | Requires an actual character under the cursor ray. Fixed/random/smart delay chooses one timing policy. Rechecks player, weapon, and eligibility at firing time. TargetOnly additionally requires the Silent Aim target. |
| ESP | Reuses boxes and labels; no per-frame Instance creation. Computes body bounds without including tools/accessories. Supports names, distance limits, visibility, fill, opacity, and predicted position. Drawing API is used when available, with native GUI fallback. |
| Gun Specifications | Normalizes bracketed weapon names and aliases internally. Selects Close/Medium/Far by distance. BoxSize sets an additional projected target box in studs; the ordinary cursor FOV must also pass. No weapon-specific prediction values. |
| Client Bullets | During shooting, redirects local `Mouse.Hit` reads to the selected aim point when compatible hooks are available. Known remote updates retain normal mouse aim when only camera assistance is active. Also adjusts recognized nearby gun/bullet/tracer Beams for the latest local shot and restores their endpoints afterward. With no selected point, normal mouse behavior remains. Arbitrary custom projectile/Trail systems are not rewritten. |
| AntiAfk | Uses the idle event and VirtualUser input where permitted by the executor. Unsupported calls produce a warning. |
| AntiFling | Limits a severe local velocity jump only when accompanied by high angular velocity. This is mitigation, not collision immunity. |
| Macro Abuse | After an eligible activation: wait briefly, unequip, hold Ctrl, equip, release. Only one cycle runs. Work With TB controls triggerbot activations. Cancellation restores the unequipped tool when appropriate and releases only Ctrl input the script owns. |
| Prefire | While active, detects a replicated opponent Ammo decrease within range and schedules one checked activation after Delay. It does not predict unseen future peeks. Games that do not replicate Ammo need a different observation adapter. |
| Intro | Bundles the approved 1800-pixel letter animation, lingering blur, and layered bell. Only assets download, using the existing local cache. No intro options are exposed in the configuration. |

## Replacement and cleanup

Re-execution disconnects the old event subscriptions, removes its render binding and visuals, stops its intro, and cancels pending shots and macro input. It retains toggle states, selected player IDs, and whitelist changes when their original config values have not changed. Explicitly changed config values win. Hold states reset; release and press held bindings again after replacement.

The two hook dispatchers are installed once and switch to the current runtime. Panic makes them pass through; it does not blindly restore an old metamethod and overwrite another script's hook. There is no growing hook chain across neoperro replacements.

Target scans and velocity sampling run at 30 Hz. Camera smoothing and visual projection run at the render rate. Body bounds refresh four times per second, and ESP visibility checks are cached briefly. This does not set an FPS cap or guarantee 120 FPS on a particular machine.

## Integration and limits

Looten supplied the `ReplicatedStorage.MAINEVENT` remote, `MOUSE` argument, Vector3 payload, Tool.Activated integration, crew path, knocked path, and weapon names. Its AntiCurve and Anti-AimViewer flags were not implementations. Goodnight supplied configuration ideas; its remote loader was not executed.

The new script sends aiming coordinates through the known remote and fires automation through `Tool:Activate()`. It does not invent a damage remote. Without namecall support it falls back to Looten's activation-time coordinate update; Anti-AimViewer cannot operate in that mode. Missing remote/hook/input capabilities generate warnings instead of being described as working.

The implementation has not been executed against the live games or a real executor here. In particular, remote ordering, server acceptance, local tracer implementations, replicated Ammo, Ctrl crouch behavior, and executor permissions need in-game verification. No claim of perfect hit registration or undetectability is made.

For a report, include the game, weapon name, affected feature, and the exact error or warning. Capabilities and one-time warnings can be inspected with:

```lua
local runtime = getgenv().__neoperroRuntimeV1
if runtime then
    for name, value in pairs(runtime.Capabilities) do print(name, value) end
    for name, message in pairs(runtime.Warnings) do warn(name, message) end
end
```

## Verification

`python build-neoperro.py` regenerates the bundled files. `python tests/run-lua.py tests/core.spec.lua tests/runtime.spec.lua` syntax-checks them with Lua 5.4 and runs portable math tests plus a deterministic Roblox mock. These are not Roblox engine or Luau bytecode tests.

Checks cover equivalent damping at 30/60/120/240 FPS, circle/box boundaries, input devices, weapon aliases and distance boundaries, whitelist rules, delay policies, velocity history and teleport resets, config preservation, startup/cleanup, shared keys, nonstacking hooks, packet pass-through, target checks, cancelled delayed shots, the Ctrl macro sequence, panic cleanup, native GUI fallback, Y-Axis modes, both AntiCurve bounds, ammo-based prefire, respawn, and player removal.

## Sources and method choices

- [Looten source](https://github.com/kasztingers11-lang/mysite/blob/main/Looten): game integration reference. Its original implementation was read, not executed.
- [Roblox camera documentation](https://create.roblox.com/docs/reference/engine/classes/Camera): consistent viewport projection; on-screen projection alone does not establish visibility.
- [Roblox raycasting guide](https://create.roblox.com/docs/workspace/raycasting): explicit filtered rays for visibility and crosshair detection.
- [Roblox Tool documentation](https://create.roblox.com/docs/reference/engine/classes/Tool): activation/deactivation through the tool interface.
- [DevForum discussion of frame-rate-independent lerp](https://devforum.roblox.com/t/frame-rate-independent-lerp/352375/18) and [Rory Driscoll's derivation](https://www.rorydriscoll.com/2016/03/07/frame-rate-independent-damping-using-lerp/): exponential decay instead of a fixed per-frame interpolation factor.
- [DevForum discussion of replicated prediction jitter](https://devforum.roblox.com/t/predicting-player-position-in-postsimulation-jittering-for-other-clients/3012082): replication jitter remains a limitation; timestamp fitting cannot reveal a hidden server position.
- [Roblox BindToRenderStep documentation](https://create.roblox.com/docs/reference/engine/classes/RunService/BindToRenderStep): schedule camera adjustments after the default camera.
- [sUNC hookmetamethod](https://docs.sunc.io/Closures/hookmetamethod/) and [getnamecallmethod](https://docs.sunc.io/Metatable/getnamecallmethod/): optional executor interface contracts, separate from standard Roblox APIs.
