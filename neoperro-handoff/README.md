# neoperro - current repair handoff

Current runtime: **1.3.9**, branch **repair/neoperro-evidence**. Main is older.
Use the repository-root `neoperro.lua` (commented table plus repair-branch loader)
or `neoperro-full.lua` (full bundle). Preserve local edits before switching branches.

## Read first

1. [Current continuation instructions](docs/NEXT-SESSION.md)
2. [Live observations and limitations](docs/SESSION-2026-10-22.md)
3. [Repair history](docs/REPAIR-LOG.md)
4. Remaining docs, Looten reference, and all four reference screenshots.

The root config, neoperro-src modules and neoperro-intro/preview.lua are authoritative.
Rebuild generated files with `python build-neoperro.py`; run
`python tests/run-lua.py tests/core.spec.lua tests/runtime.spec.lua`.
Windows tests can use Lupa's Lua 5.4 backend. Mocks do not prove Roblox compatibility.

## Historical material

`source-snapshot/` and the root `neoperro-handoff-current.zip` are historical 1.2.0
artifacts, NOT the current release. Do not restore them over current sources.
Older requirement/bug documents describe the earlier repair; the current session
record and NEXT-SESSION take precedence for implementation and validation status.
MANIFEST.json checks the current handoff directory, excluding itself; it does not
certify runtime behavior or update the historical ZIP. Repository consolidation
and refreshing/removing the historical snapshot remain pending.

Never store executor credentials. Keep supported game IDs internal to runtime.

Latest feedback repairs and evidence: [session 2026-10-23](docs/SESSION-2026-10-23.md).
