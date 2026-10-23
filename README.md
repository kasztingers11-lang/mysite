# neoperro 1.3.8 - testing build

Use [neoperro.lua](neoperro.lua): edit the table and execute the whole file.
Its bottom loader fetches **repair/neoperro-evidence**. Main is older.
[neoperro-full.lua](neoperro-full.lua) contains the same table and runtime.

This repair fixes standalone ESP weapon profiles, removes the 60 Hz drawing cap,
recovers physically held activation keys, and adds shared muzzle/camera geometry.
Prediction uses bounded speed response, validated turn compensation and measured
vertical acceleration. The table uses **Activation** and **Triggerbot check**;
older names migrate internally.

Default controls: P Silent toggle, T Target selection, M Assist toggle, hold Q
Assist, V Triggerbot toggle, hold RMB Triggerbot, Z ESP, E unload.
A keybind's third entry selects Keyboard or Mouse. Re-execution retains valid
toggles; Enabled=false remains a hard gate.

Gun Specifications must be enabled with a supported gun equipped. Close, Medium
and Far are upper distance bounds; beyond Far uses the general size. Profiles
also change standalone ESP when the Silent box is hidden.

Live local fixtures verified profile ranges, Q/RMB selection and release,
third-person muzzle alignment/obstruction, and drawing on every frame at about
240 Hz. One native jump replay reduced vertical forecast error. These are not
server damage or hit-rate tests. The latest server had no second player.
Lua regression suites pass; mocks do not prove Roblox compatibility.
Full-bundle static analysis still reports dynamic/optional-state type findings.

[Settings reference](NEOPERRO.md) |
[Exact evidence and limitations](neoperro-handoff/docs/SESSION-2026-10-23.md) |
[Remaining validation](neoperro-handoff/docs/NEXT-SESSION.md)

Authoritative sources are neoperro-config.lua, neoperro-src/ and
neoperro-intro/preview.lua. Rebuild with python build-neoperro.py and validate
with python tests/run-lua.py tests/core.spec.lua tests/runtime.spec.lua.
The historical handoff snapshot/ZIP remains 1.2.0. Preserve local edits.
No executor credentials belong in the repository.
