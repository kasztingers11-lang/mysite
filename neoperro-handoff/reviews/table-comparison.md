# Pending table proposal — 2026-10-23

Comparison baseline: the complete comment-free table supplied after release 1.3.11,
matching the current authoritative config semantically. Only table literals were
parsed; the user's pasted file was not executed.

The proposal is a review draft. It is not wired into the runtime, is not the
runtime defaults file, and intentionally has no loader. Decisions about omitted
settings are pending before integration.

## Moved, renamed or added by the user

- Checks moved to the top; Y-Axis follows it.
- Resolver moved from Silent Aim to a shared top-level block; Enabled stays true.
- Silent Aim.GroundShotCheck moved/expanded to Checks.GroundShotCheck = {true, true, true}.
- Y-Axis.JumpOffset became Offset; its numeric value stays 1.0.
- Y-Axis adds Aim Assist = true and Triggerbot = true.
- Gun Specifications moved to the bottom; its ranges and profiles are unchanged.
- Every scalar/array value retained at the same path is unchanged.

## Omitted settings requiring a decision

| Removed from the editable table | Previous value | Scope |
| --- | --- | --- |
| Client Bullets.Enabled | true | Entire section omitted |
| Anti-AimViewer.Enabled | true | Entire section omitted |
| Aim Assist.Ignore | false | FOV bypass option omitted |
| 2d-Box.Predicted Position | true | Silent Aim, Aim Assist, Triggerbot |
| 2d-Box.Max Distance | 5050 | Silent Aim, Aim Assist, Triggerbot |
| 2d-Box.Filled | false | Silent Aim, Aim Assist, Triggerbot |
| 2d-Box.Transparency | 1 | Silent Aim, Aim Assist, Triggerbot |

These are 15 omitted setting instances, plus three original paths that were moved
or renamed. Resolver and GroundShotCheck still exist in new locations; Offset
replaces JumpOffset. ESP.MaxDistance remains 5050, separately from removed box
distance fields. No complete feature was removed from the runtime.

The current runtime merges defaults: omitting a field does not disable/delete its
behavior. It also does not yet consume the new shared Resolver, shared ground-shot
checks, Offset, or Y-Axis feature flags. Wiring is required before this proposal
can replace the current table.

## Naming applied in the aligned draft

- Existing Mode keys become Method, including Unlock Mode -> Unlock Method and
  DelayMode -> DelayMethod.
- Existing Closest.Method becomes Closest.Selection; Part/Point values stay unchanged.
- Mode values such as Auto, Target, 2d-Box and 3d-angles do not change.
- Resolver still exposes only Enabled; TrueVelocity stays internal.
- Assignments align within each table block. Arrays, colors, dimensions and gun
  profile entries stay compact. No comments were added to the draft table.

## Exact parsed field differences before naming changes

### Removed original paths

- `2d-Box.Aim Assist.Filled` = `false`
- `2d-Box.Aim Assist.Max Distance` = `5050`
- `2d-Box.Aim Assist.Predicted Position` = `true`
- `2d-Box.Aim Assist.Transparency` = `1`
- `2d-Box.Silent Aim.Filled` = `false`
- `2d-Box.Silent Aim.Max Distance` = `5050`
- `2d-Box.Silent Aim.Predicted Position` = `true`
- `2d-Box.Silent Aim.Transparency` = `1`
- `2d-Box.Triggerbot.Filled` = `false`
- `2d-Box.Triggerbot.Max Distance` = `5050`
- `2d-Box.Triggerbot.Predicted Position` = `true`
- `2d-Box.Triggerbot.Transparency` = `1`
- `Aim Assist.Ignore` = `false`
- `Anti-AimViewer.Enabled` = `true`
- `Client Bullets.Enabled` = `true`
- `Silent Aim.GroundShotCheck` = `true`
- `Silent Aim.Resolver.Enabled` = `true`
- `Y-Axis.JumpOffset` = `1.0`

### Added paths

- `Checks.GroundShotCheck` = `{true, true, true}`
- `Resolver.Enabled` = `true`
- `Y-Axis.Aim Assist` = `true`
- `Y-Axis.Offset` = `1.0`
- `Y-Axis.Triggerbot` = `true`

Changed values at retained paths: 0.

### Naming changes applied to the draft

- `Y-Axis.Mode` -> `Y-Axis.Method`
- `Silent Aim.Mode` -> `Silent Aim.Method`
- `Silent Aim.Target.Closest.Method` -> `Silent Aim.Target.Closest.Selection`
- `Silent Aim.Fov.Mode` -> `Silent Aim.Fov.Method`
- `Silent Aim.Activation.Unlock Mode` -> `Silent Aim.Activation.Unlock Method`
- `Silent Aim.AntiCurve.Mode` -> `Silent Aim.AntiCurve.Method`
- `Aim Assist.Mode` -> `Aim Assist.Method`
- `Aim Assist.Target.Closest.Method` -> `Aim Assist.Target.Closest.Selection`
- `Aim Assist.Fov.Mode` -> `Aim Assist.Fov.Method`
- `Aim Assist.Activation.Unlock Mode` -> `Aim Assist.Activation.Unlock Method`
- `Triggerbot.DelayMode` -> `Triggerbot.DelayMethod`
- `Triggerbot.Fov.Mode` -> `Triggerbot.Fov.Method`
- `Whitelist.Mode` -> `Whitelist.Method`
