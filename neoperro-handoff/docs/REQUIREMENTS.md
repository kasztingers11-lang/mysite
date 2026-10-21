# Requested behavior

## Latest follow-up after testing the repaired full bundle

The user reported it “works okay,” but Y-Axis Auto still shoots the ground. Auto must prevent ground-directed shots; diagnose and test the actual failure before selecting a correction. Silent Aim needs further improvement using relevant Looten logic and balanced tuning supported by observations. These follow-up repairs are outstanding; see NEXT-SESSION.md. The current IDs replace Looten's old IDs and must remain internal.

These are the user's requested outcomes, not claims about the current implementation.

## Delivery and lifecycle

- Keep a readable, commented `getgenv()['neoperro']` configuration at the top and a runtime loadstring at the bottom. Explain settings in Lua comments.
- Re-execution replaces the previous instance automatically: disconnect signals, remove old drawings, cancel pending actions, release owned inputs, and avoid accumulating hooks. No Reload or Replace Previous setting.
- Multiple features may share a keybind. Tuples use strings, such as `{'Q', 'MouseButton2', 'Mouse'}`, instead of Enum values in the table.
- Keep place IDs inside the runtime: Da Strike `134196333708867`, Da Uphill `71324444457408`, Da Downhill `139144803593140`. The user says these games share their implementation; that still needs verification.
- Keep the approved large, clean gothic N intro, with only the letter swirling from small to large, a longer blur, gothic audio, and a smooth fade. No block behind it and no intro settings in the config. Run it only once per client session, including across replacements. The preview source is included; the original logo artwork is not one of the four supplied screenshots.

## Targeting and prediction

- Silent Aim Auto chooses eligible targets without a selection key. Target mode uses a selection key. Ignore bypasses FOV restrictions; there is no separate Sticky or IgnoreFov setting.
- Aim Assist Auto searches for the nearest eligible target to the crosshair continuously while its activation key is held. Target mode can retain explicit selection.
- Target settings use BasePart and a nested Closest table: Enabled, Raycast, Method (`Part`/`Point`), Axis (`Center`/`All`), Sharpness, and Reduce.Center/All.
- Closest disabled uses BasePart. Part means a part center. Point means a point inside reduced bounds. Raycast uses the actual surface under the cursor and bypasses reduction for that hit. Reduce 0 allows edges; 1 collapses to center. Sharpness controls point response.
- Center/All describes movement of the selected point inside its part. Do not accidentally preserve manual X/Z in the final Silent Aim output, which caused misses in an earlier interpretation.
- Prediction defaults: SilentAim `0.128`, AimAssist `0.121`, Triggerbot `0.121`. Document units and prevent applying prediction twice.
- Y-Axis has Auto and Custom. Auto ignores JumpOffset and chooses its automatic adjustment. Custom uses JumpOffset without also choosing the automatic adjustment. Preserve independent SilentAim/AimAssist switches. The exact automatic model still needs validation.
- Checks remain separate for Silent Aim, Aim Assist, and Triggerbot: Dead, Knocked, Wall, ForceField, Crew, Tool.
- Remove top-level EndMath. Keep its applicable settings inside Silent Aim. AntiCurve offers `3d-angles` and `endmath`; remove exposed MaxAngle fields. Use actual muzzle geometry where relevant. See IMAGES.md for the user's distance-based examples; they do not establish a universal server-side anti-curve method.
- Review Looten's resolver and actual shot path before replacing them with assumptions. Anti-AimViewer is requested, but concealment from administrators must not be presented as verified.

## FOV and ESP

- `2d-circle`: circle around the crosshair, selecting targets inside it.
- `2d-box`: a box around each player; selection occurs when the crosshair enters that player's box. It is not a cursor-centered rectangle.
- Separate box styles for Silent Aim, Aim Assist, Triggerbot: Visible, Predicted Position, Name enabled/type, foreground and outline RGB arrays, Width/Height, Max Distance, Filled, Transparency. Requested example dimensions: 5 by 4.3.
- ESP boxes should have stable character-relative dimensions rather than changing with limb animation. They still follow characters and perspective; “static” does not mean frozen screen coordinates.
- Silent Aim's box style overrides ESP only when that box's Visible setting is true. Otherwise ESP uses fixed 6 by 6 world dimensions and remains independently visible.
- Dead checks must hide the relevant dead-player box and name.
- Whitelist coloring overrides normal ESP colors: green for assigned friends, red for assigned targets.

## Whitelist

- Enabled false clears assignments and removes whitelist effects and coloring, including preserved state on re-execution.
- Friend mode excludes assigned IDs; Target mode only allows assigned IDs. Keep up to four player assignments and only AssignKey. Remove ClearKey and ToggleModeKey; change mode in the table.

## Triggerbot and weapons

- Add a configurable held activation input, e.g. RMB or Q, in addition to enable/toggle behavior.
- Fov.Enabled false means actual character under the cursor; true means the configured box/circle selection boundary. TargetOnly restricts firing to the Silent Aim target.
- Preserve Delay, RandomDelay, SmartDelay, and their explicit behavior. Compare timing with Looten rather than assuming reaction delay and button hold duration are interchangeable.
- Gun Specifications retains ranges and per-range BoxSize for the supported weapon names. Remove per-gun prediction values, placeholder Silencer/SMG UseDefault entries, and exposed aliases.
- Client Bullets exposes Enabled only. Requiring a valid target is internal and always enforced; no RequireTarget setting. Verify supported tracer implementations rather than claiming universal redirection.

## Misc

- Macro Abuse has Enabled, Work With TB, Check Ammo, and Macro Check. Disabled must cancel and prevent all macro actions. Detect an actual macro rather than ordinary walking. Intended sequence after an eligible shot: unequip, hold Ctrl to crouch, equip, then release owned Ctrl. Preserve manual and Triggerbot distinctions.
- Keep AntiAfk, AntiFling, and Prefire. Validate the claimed trigger and effect of each; replicated events do not reveal future information.
- Panic has Enabled plus Keybind. It unloads owned behavior and visuals and releases owned inputs.
