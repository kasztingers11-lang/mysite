# Latest priority: user-feedback repairs 1.3.2

Read [SESSION-2026-10-23](SESSION-2026-10-23.md) first. It supersedes older status below.
User confirmed shot-time aim-view snap is expected. Character scaling now lives at
Triggerbot.Fov.Character (default 1.2; 1 actual; smaller/larger supported). SmartDelay
awaits user decision, and Macro Check awaits demonstration. Continue focused live
Auto Y, Character edge/occlusion tests and the user's specific Prefire reproduction
before the older backlog. Current source/bundles are root files on repair/neoperro-evidence.

---

# Continue neoperro 1.3.1

Use branch `repair/neoperro-evidence`; main and the portable 1.2.0 snapshot/ZIP are
older. Preserve existing local changes. Root sources are authoritative. Read the
session evidence, repair history, remaining docs and four reference screenshots.

## Current verified status

- Rebuilt current bundles with no output changes. Both Lua 5.4 assertion suites and
  four generated/config syntax checks passed on 2026-10-22.
- Live, low-ping moving trials: Auto and manual 0.128 each produced damage in one
  shot; manual 0.250 produced none in its one trial. This is not a hit-rate estimate.
- Isolated held-RMB Triggerbot, FOV=false: no attempts before holding; three attempts,
  two ammo drops, health 100 to 33; owned input released. Attempts are not shots.
- Smaller cat intro, dim screen and blur rendered. Engine reported meow playback;
  auditory quality was not independently verified. Intro runs once per session.
- Auto Y direction-change correction uses captured jump-apex values in passing
  mocks. Follow-up live capture had zero eligible frames after focus loss, so the
  latest correction is NOT live accepted.

## Remaining work, in order

1. Verify latest Auto Y correction during rising, falling and landing. Capture
   selected part, raw/history/resolved velocity, vertical source/adjustment, final
   point, ground support, muzzle origin, actual MOUSE payload, ammo and damage.
   Distinguish selection, submitted coordinates and observed shot results.
2. Measure prediction at higher ping and across weapons; current Auto is a bounded
   latency estimate for this hitscan game, not calibrated server timing. Do not
   infer projectile speed or tune from cross-client alignment alone.
3. Test Silent closest/raycast and explicit Target mode, then feature combinations.
   Test Triggerbot cadence, release, reload, target loss, swaps and respawn.
4. Validate AntiCurve's existing 2.2-stud and 120-pixel modes, custom local Beam
   redirection, Macro Abuse ammo/Ctrl lifecycle and Aim Assist smoothing live.
5. Measure combined-feature combat cost; tidy repository and historical portable
   artifacts only after preserving source, references and useful evidence.

## Constraints and evidence discipline

Before future live work discover REAL tools, check diagnostics/console and actual
client/runtime/weapon. Previous live input stopped when the user pressed Escape;
this finishing pass performed no new live tests. Check current user authorization
before resuming desktop input. Never print or save executor credentials.

Keep commented config plus bottom loader, shared binds, independent feature gates,
replacement/input/drawing cleanup, session-once intro without settings, whitelist
and ESP fixes. Auto Y ignores JumpOffset; Custom is separate. Prediction belongs
inside each feature with Enabled/Auto/Value. Triggerbot defaults to hold RMB with
V to arm/disarm. Loader now fetches this repair branch.

The hardened MAINEVENT/MOUSE send validates coordinates and stale remotes and
records failures without retrying old points. Its shot-window setting does not
prove concealment from administrator aim viewers. Do not describe it as verified.

Edit authoritative files, rebuild, run meaningful regressions and push reviewable
changes. Report mocks separately from live observations. No runtime change is
required merely to produce a new commit when the checks reveal no regression.
