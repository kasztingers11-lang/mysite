# neoperro 1.3.5 — testing build

Current branch: `repair/neoperro-evidence`. Main is older.

Use [neoperro.lua](neoperro.lua): edit its commented settings table and execute the
whole file. Its bottom loader now fetches this repair branch's runtime.
[neoperro-full.lua](neoperro-full.lua) is the equivalent bundled script. Logo/audio
download once and reuse the local cache. No executor credentials belong in this repo.

## Default controls

| Input | Action |
| --- | --- |
| P | Toggle Silent Aim |
| T | Select Silent target in Target mode |
| M | Toggle Aim Assist |
| Hold Q | Aim Assist search |
| V | Arm/disarm Triggerbot |
| Hold RMB | Activate armed Triggerbot |
| Z | Toggle ESP |
| R | Assign whitelist entry when enabled; also overlaps the game's reload key |
| E | Panic/unload |

Triggerbot FOV=false uses Fov.Character: 1 = actual hit, 1.2 = larger native body/HB bounds,
0.8 = smaller bounds. It never resizes characters. Prediction has
independent Enabled/Auto/Value settings for each feature; Auto ignores Value.
Auto Y ignores JumpOffset; Custom uses it separately. Feature Enabled=false is a
hard gate even if its key toggle remains armed. Intro plays once per client session.

## What is verified

- Both Lua 5.4 mock suites and generated/config syntax checks pass.
- Controlled low-ping moving trials: one Auto hit, one manual 0.128 hit, one manual
  0.250 shot without observed damage. This is not a general hit-rate claim.
- Triggerbot held-RMB/FOV-off produced ammo consumption and damage with other aim
  features disabled; released input afterward.
- Cat intro rendered with the smaller logo and blur; the latest preview has no tinted backdrop. Engine reported
  the original synthesized meow loaded and playing for 2.1 seconds.

See [session evidence](neoperro-handoff/docs/SESSION-2026-10-22.md) for exact limits.
Auto Y's newest jump-apex correction passes recorded-value regressions; its live
follow-up was interrupted by focus loss. High-ping acceptance, broad weapon timing,
Macro Abuse, custom tracer behavior and complete feature combinations remain open.
Anti-AimViewer now restores ordinary aim after an explicit shot send and passes
continuous MOUSE updates through. One controlled manual shot hit with no observed
observer-line snap; broader latency/automatic-fire validation remains open.

## Development

Authoritative files: `neoperro-config.lua`, `neoperro-src/`,
`neoperro-intro/preview.lua`. Generated files should be rebuilt, not hand-edited.

```sh
python build-neoperro.py
python tests/run-lua.py tests/core.spec.lua tests/runtime.spec.lua
```

Tests require a Lua 5.4 shared library or Python Lupa's lua54 backend. Mock tests do
not prove Roblox compatibility. The old portable handoff snapshot/ZIP is still
1.2.0; use current repository-root files. Repository consolidation is pending.

Latest feedback repairs and evidence: [session 2026-10-23](neoperro-handoff/docs/SESSION-2026-10-23.md).

1.3.4 preserves native pellet spread/color during local-only visual redirection.
Macro Abuse no longer has Check Ammo; Macro Check follows this game's Head XZ
speed >30 condition with a 120ms pre-shot buffer. Live trial rejected stationary
shots and accepted seven fast-movement activations; see the session evidence.

1.3.4 priority delivery: deferred shot-time aim restoration. See the session log
for the controlled manual shot result, test limits and clean-client instructions.

1.3.5 fixes Character scaling around the game's native transparent HB, preserving
exact native hits at scale 1. Live cursor sweeps now select outside native bounds
at 1.3 and reject those points at 1; shrinking rejects native edge hits. These were
selection tests with firing disabled. Client tracer and Macro Abuse regressions
still pass unchanged, as does the confirmed aim-restoration path.
