# 1.3.3 pellet/macro follow-up

See SESSION-2026-10-23.md for native effect source evidence, spread/style checks,
Macro Check's game-derived velocity condition, removed ammo setting, and limits.

---

# 1.3.2 feedback repair

See [2026-10-23 evidence and changes](SESSION-2026-10-23.md). Two-client local tracer
separation and one Prefire response were observed; airborne follow-up lacked focus.
Expanded/shrunken trigger bounds, predicted FOV, gun-box separation and knocked ESP
pass mocks. Full details and limitations are in that record. Older history follows.

---

# Current status: 1.3.1 (2026-10-22)

See [session evidence](SESSION-2026-10-22.md) for the subsequent local REAL work and
[NEXT-SESSION](NEXT-SESSION.md) for current outstanding work. The older 1.2.0 log
below is historical: its branch, loader and no-local-MCP statements are superseded.
Current delivery branch is repair/neoperro-evidence; its loader uses that branch.

Final verification pass rebuilt identical outputs; both Lua 5.4 mock suites and
four syntax checks passed. No new code regression was revealed, so no speculative
runtime edit was made. No new live testing occurred during this pass.

---

# Repair evidence — 1.2.0

Branch: `repair/neoperro-runtime`. The repaired code and handoff are delivered on this branch; main retains the earlier build until merged. Complete live Roblox acceptance remains OPEN. After trying the full bundle, the user reported “it works okay,” but Auto Y still shoots the ground and Silent Aim needs further work. This is partial user feedback, not a controlled acceptance result. Passing Lua mocks does not establish shot acceptance, executor permissions, visuals, audio, or current game compatibility.

## Source of truth and build

Edit `neoperro-config.lua`, `neoperro-src/core.lua`, `neoperro-src/runtime.lua`, and `neoperro-intro/preview.lua`. `python3 build-neoperro.py` generates `neoperro-src/defaults.lua`, `neoperro.lua`, `neoperro-full.lua`, and `neoperro-runtime.lua`. The portable `source-snapshot/` was refreshed with these repaired files for transfer to the next local session; it is no longer the original baseline. The builder no longer rewrites its config input or creates the redundant `neoperro-config-updated.lua`.

The original checked-in full/runtime bundles differed from a fresh build before repairs. Fresh bundles are now generated from editable sources. The loader retains the commented config and final runtime loadstring; it still fetches **main**, so it will not fetch these local branch repairs until they reach main. To validate this revision locally, use this branch's complete `neoperro-full.lua`; do not confuse an old main download with the repaired bundle. The intro still fetches the documented immutable image/audio assets.

## Evidence by bug

| ID | Concrete finding and implementation | Verification / remaining work |
| --- | --- | --- |
| B01 | The existing Tool.Activated callback already sent MOUSE/Vector3, like Looten. A shared top-level final wall gate could reject every Silent point even when the feature's initial checks passed. EndMath is now Silent-only and explicit. Added `Diagnose()` to inspect equipped tool, remote presence, target IDs, send/activation counters and capabilities. | Mock shot payload routing passes. No claim that this explains every reported miss. Current games/weapon controllers and server acceptance need runtime evidence. |
| B02 | Old code waited Delay before pressing and released after fixed 0.04 seconds. Looten presses first and uses Delay as hold duration. Use one immediate press/hold/release cycle, random/smart hold alternatives, cancellation on activation/target loss, and native input with virtual/Tool fallbacks. Retain shot context across a failed input backend and refresh held target points. | Immediate press, no overlap, held duration, loss/release, shared activation and fallback behavior pass mocks. Live weapon timing is open. |
| B03 | Shared final EndMath wall gates applied to Assist as well as Silent. Moved these into Silent Aim. Assist keeps independent selection/prediction and hold-to-search. | Assist works in mocks with Silent disabled and with a muzzle obstruction rejecting Silent. Camera/native runtime behavior remains open. |
| B04 | Disabled and observed-macro guards already existed; walking alone is rejected in the existing mock. A recent ammo drop could be reused after a cancelled cycle. Consume each confirmed drop once; preserve live disable and owned Ctrl cleanup. | Disabled, walking, observed I/O alternation, fresh ammo confirmation, consumed confirmation and live cancellation checks pass. External macros that do not expose inputs are not detectable by this heuristic. |
| B05 | Every rendered style required its Visible flag; hiding Silent style removed standalone ESP. Added independent root-centered 6x6 fallback, unaffected by weapon profile or hidden Silent distance. Visible Silent style still overrides. Isolate rendering errors per player. | Stable dimensions, hidden style fallback, dead checks, names, colors and one failing player's Drawing pass mocks. Actual overlay geometry remains open. |
| B06 | Disabled whitelist still restored assignments and applied markers; assignment input remained active. Clear on initialization and heartbeat, skip restoration/assignment, gate marker colors. | Disabled assignment/removal, replacement, enabled friend/target filtering and colors pass. |
| B07 | Tool changes/respawn did not immediately release held automated input. Input backend failure could lose cycle metadata. Added release on weapon/character removal and startup generation guard around yielding PlayerGui lookup. Existing hook dispatchers remain shared; cleanup remains owned. | 20 replacements alternate source and generated runtime, keeping one render binding and constant connection count; old drawings removed and mouse released. Final teardown removes all Drawings. Concurrent yielding startup and real executor hooks still require live checks. |
| B08 | Trigger prediction default was 0.132 instead of 0.121. Corrected it; lead is applied once in seconds. History remains bounded and reset on discontinuities. Auto/Custom Y behavior remains explicit and mutually exclusive. | Math/history and Custom/grounded Auto checks pass. Looten's resolver is a heuristic; its fixed speed-16 movement fallback was reviewed, not copied as authoritative velocity. User now reports Auto still shoots the ground. This follow-up is NOT FIXED; investigate live vertical intermediates and the shot endpoint. Existing grounded Auto mocks do not cover or resolve the reported failure. |
| B09 | Exposed degree limits and a world-space lead clamp contradicted distance examples. Removed MaxAngle and top-level EndMath. User confirmed 3d-angles Max=2.2 studs from ordinary Mouse.Hit and endmath Radius=120 pixels around cursor. Reject outside the selected radius; do not truncate lead. | Distance rejection/accepted unmodified lead and config shape pass. This is an explicit user-confirmed interpretation, not a recovered Looten algorithm or server guarantee. |
| B10 | Looten exposes Anti-AimViewer switches but supplies no complete corresponding algorithm. Preserve shot-scoped MOUSE updates and idle pass-through. | Idle pass-through and shot redirection pass mocks. Spectator/admin concealment is unverified and not promised. |
| B11 | Shared keys already dispatch to all matching actions. Preserved that path while separating final filters and owned input lifecycle. | Shared Q/P inputs, focus/typing, respawn, Panic enabled/disabled, GUI fallback and replicated-ammo Prefire pass mocks. AntiAfk, AntiFling, arbitrary tracers, and interactions in current games remain live checks. |

## Looten comparison and API evidence

`Looten` and `references/Looten.reference.lua` contain the same code except for one trailing newline. Relevant inspected areas:

- Lines 148–175: game table uses MAINEVENT/MOUSE but **different place IDs** from the requested three. The user confirmed these are old IDs. The active runtime deliberately uses the user-supplied current IDs: Da Strike 134196333708867, Da Uphill 71324444457408, Da Downhill 139144803593140. This is not a configuration blocker; live shot acceptance remains untested.
- Lines 670–800: target point/velocity calculation, resolver movement heuristics, falling adjustments, and Tool.Activated MOUSE/Vector3 updates. Neoperro retains/adapts the activation send pattern with its own config, eligibility and lifecycle; no bulk copy or numerical reuse percentage is claimed.
- Lines 1406–1417: native Mouse.Target ancestry, press, wait Delay, release. Neoperro adapts this sequence with ancestry walking, a portable raycast fallback, hold activation, non-overlap and cancellation. The native path is preserved rather than requiring Tool.Activate alone.
- Resolver movement fallback multiplies MoveDirection by 16 and prediction; it is not recovered authoritative velocity. Existing timestamped history remains an explicit alternative, with no compatibility claim.

Official Roblox API reference source was retrieved during this repair from `Roblox/creator-docs` on GitHub. It confirms that Mouse.Target can be nil, Mouse.Hit is a world CFrame, Tool.Activated is a click event and does not fire with Ctrl pressed, and GetMouseLocation/viewport projections do not apply the GUI inset. This runtime uses raw mouse/viewport coordinates and IgnoreGuiInset overlays. Native Ctrl macro behavior must therefore be checked with actual activation.

- [Tool](https://create.roblox.com/docs/reference/engine/classes/Tool)
- [Mouse](https://create.roblox.com/docs/reference/engine/classes/Mouse)
- [Camera](https://create.roblox.com/docs/reference/engine/classes/Camera)
- [UserInputService](https://create.roblox.com/docs/reference/engine/classes/UserInputService)
- [GuiService](https://create.roblox.com/docs/reference/engine/classes/GuiService)

No new developer-forum evidence is claimed. Neither the API reference nor the screenshots establishes game-specific remotes, anti-curve guarantees or executor compatibility.

## Commands and outcomes

`python3 build-neoperro.py`: successful regeneration. `python3 tests/run-lua.py tests/core.spec.lua tests/runtime.spec.lua`: both assertion suites pass; four generated/config Lua files compile under Lua 5.4. The runtime suite also executes the generated runtime during repeated replacement, not just the editable body. The cloud agent ran no live engine, network loader, server damage or visual/audio test. The user subsequently reported the full bundle works okay, with Auto Y ground shots remaining; no controlled game/weapon/runtime evidence was supplied. A zero-test syntax-only result is not being counted as functional validation.

## Short in-game checklist

Use a private test session you control. Start with this revision's full bundle; check `Version` is `1.2.0`.

1. One feature at a time: Silent Auto and Target with each supported weapon; distinguish target selected, MOUSE packet sent, and damage accepted. Record place/weapon/runtime/error and failures.
2. Trigger: hold/release activation, lose the target, reload/empty ammo, swap weapons and respawn; verify every press is released. Try shared Q with Assist.
3. Assist with Silent off, then on; hold-to-search must retarget, releasing stops it.
4. Re-execute repeatedly, including during mouse hold and macro Ctrl hold. Expect one overlay/runtime, no stuck input, and one intro per session. Panic cleans everything.
5. Hide Silent box: ESP remains 6x6. Test death, whitelist enable/disable/re-execution and both assignment modes. Macro disabled/walking must do nothing; eligible shots require a fresh ammo decrease and observed macro inputs.
6. Only after the basic shot works, test prediction, Auto/Custom Y, each AntiCurve mode separately, and intro appearance/audio. Record accepted/rejected geometry rather than assuming a modifier fixes server shots.

For a console report (no secrets), run:

```lua
local r = getgenv().__neoperroRuntimeV1
if r then
    local d = r:Diagnose()
    print('Version', d.Version, 'Tool', d.Equipped, 'Remote', d.Remote)
    for k,v in pairs(d.Targets) do print('Target', k, v) end
    for k,v in pairs(d.Stats) do print('Counter', k, v) end
    for k,v in pairs(d.Capabilities) do print('Capability', k, v) end
    for k,v in pairs(d.Warnings) do warn(k, v) end
end
```

Real MCP shown by the user is a Windows-local server. This cloud machine cannot reach that PC's loopback server. Connect it to a local Codex client on that PC, start a new session, and continue using this branch's changes. No Real MCP tool is available in this cloud session.

## Latest continuation status

See [NEXT-SESSION.md](NEXT-SESSION.md). The user is moving to a local Codex chat with Real MCP to diagnose Auto Y ground shots and improve Silent Aim from Looten evidence. No runtime changes were made as part of this handoff refresh.
