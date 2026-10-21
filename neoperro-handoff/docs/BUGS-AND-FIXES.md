# Bugs and proposed fixes

All rows are OPEN. Reports come from the user; causes and fixes below are investigation proposals, not completed work.

| ID | Report / requirement | Proposed investigation or repair | Acceptance check |
| --- | --- | --- | --- |
| B01 | Silent Aim does not work | Compare Looten's Tool.Activated and MOUSE payload path with the runtime; trace acquisition, checks, final point, activation and remote send separately. Avoid unrelated final gates blocking every shot. | Eligible Auto and Target shots produce the intended server-accepted result on each supported weapon/game; invalid targets remain excluded. |
| B02 | Triggerbot performs poorly | Compare native Mouse.Target acquisition and press/hold/release timing with Looten. Use one owned firing cycle and cancel it cleanly. | Held activation fires at eligible characters, stops on release/loss/death, respects ammo and selected FOV behavior, and never leaves the mouse held. |
| B03 | Aim Assist stopped | Check shared-state coupling, Silent-only final checks, target selection and render errors. | Hold-to-search continuously retargets; release stops; works with Silent Aim both enabled and disabled. |
| B04 | Macro runs when disabled, later fails to run | Enforce Enabled at entry and every pending stage; cancel owned input. Validate observable macro detection and ammo confirmation independently. | Disabled always prevents actions; walking alone never triggers; a recognized macro resumes after eligible manual/TB shots under configured rules. |
| B05 | ESP disappeared / changes with Silent settings | Decouple standalone ESP from Silent box visibility and selection. Use stable root-centered geometry and isolate per-player rendering failures. | ESP stays 6x6 when Silent box is hidden; explicit visible Silent box overrides; dead targets disappear; other players survive one rendering error. |
| B06 | Disabled whitelist retains players | Clear runtime assignments and preserved list when Enabled is false; prevent assignment while disabled. | Disabling removes restrictions and red/green markers, including after replacement. |
| B07 | Repeated execution stops updating | Audit stale callbacks, dispatchers, asynchronous loads, preserved toggles, cached fetches and cleanup. | Many re-executions leave one active runtime, fresh config, bounded drawings/connections and no stuck input. Intro runs once. |
| B08 | Prediction / Y-Axis / resolver untrusted | Restore requested prediction defaults, compare Looten's resolver, and define Auto/Custom vertical behavior explicitly. | Known velocities produce expected offsets; discontinuities are handled; Custom uses JumpOffset while Auto ignores it. |
| B09 | AntiCurve / EndMath behavior differs from screenshots | Remove top-level EndMath and exposed angular limits. Establish units and origins before implementing distance-based behavior. | Configuration matches requirements; geometry cases are reproducible; no unsupported guarantees about projectile or server behavior. |
| B10 | Anti-AimViewer unverified | Determine what source actually implements and distinguish shot-scoped updates from spectator concealment. | Document observed behavior honestly; do not claim it hides activity from administrators without evidence. |
| B11 | Features fail together | Test shared keybinds, ownership of synthetic input, targeting/visual separation, weapon changes, respawn and Panic. | Each feature works alone and in combinations without consuming or corrupting another's state. |

## Repair order

1. Establish reproducible versions and diagnostic events without flooding output.
2. Compare minimal shot and trigger paths with the supplied source.
3. Repair lifecycle and input ownership before adding further modifiers.
4. Separate selection, prediction, firing, camera and visuals; apply each setting only where intended.
5. Address whitelist, box rendering and macro gating, then the optional modifiers.
6. Build generated files, run meaningful mock/math checks, and record live test results separately.

Keep a change log with the actual files changed, evidence, remaining uncertainty and live results. Source length and a desired reuse percentage are not tests.
