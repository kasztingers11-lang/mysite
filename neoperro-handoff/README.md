# neoperro — current repair handoff

This handoff contains the **updated 1.2.0 source, generated bundles, regression tests, and repair evidence**, plus the four original reference screenshots. It supersedes the initial handoff that described every repair as only a proposal.

## Latest user feedback and next task

After trying the updated `neoperro-full.lua`, the user reported: **“it works okay, Y axis auto still shooting ground”** and requested further Silent Aim improvements using more of Looten's relevant source and more balanced behavior.

This is a user-reported partial in-game result, not a complete acceptance run. No game/weapon/executor version, console trace, settings dump, or controlled result was supplied. **Auto Y ground shots remain an explicit failure. No follow-up ground-shot fix has been implemented.** Silent Aim still needs investigation; “more balanced” is not a numerical tuning specification.

The next session should connect to **Real executor MCP locally on the user's Windows PC**, inspect runtime evidence, reproduce Auto Y ground shots, then repair vertical endpoint calculation and compare Silent targeting/prediction/firing with Looten before making further changes.

## Read first

1. [Continuation instructions and ready-to-paste prompt](docs/NEXT-SESSION.md)
2. [Implemented repairs, causes, tests and limitations](docs/REPAIR-LOG.md)
3. [Exact requirements](docs/REQUIREMENTS.md) and [bug progress](docs/BUGS-AND-FIXES.md)
4. [Looten evidence](docs/LOOTEN.md), [screenshot notes](docs/IMAGES.md), and all four files in `images/`

`source-snapshot/` now contains the **current repaired source**, not the old broken baseline. `references/` contains the supplied Looten and Goodnight sources. Neither source length nor a numerical reuse percentage is a validation target.

## Transfer and source of truth

Repository: https://github.com/kasztingers11-lang/mysite
Delivery branch: [`repair/neoperro-runtime`](https://github.com/kasztingers11-lang/mysite/tree/repair/neoperro-runtime). Fetch and check out this branch to retrieve the repaired files; main retains the earlier version until the branch is merged. You can also transfer `neoperro-handoff-current.zip` from this branch into the new session. The ZIP contains this entire handoff directory, its current source snapshot and the checksum manifest.

The repository-root editable files are authoritative during development. This handoff's `source-snapshot/` is a portable copy of their current contents. If the new checkout is still the old baseline, preserve any local edits first, then deliberately transfer the snapshot's config, modules, builder, tests and bundles into that checkout. The portable intro is named `neoperro-intro-preview.lua`; in a normal checkout it comes from `neoperro-intro/preview.lua`. Compare the two before overwriting any existing intro. Do not treat the snapshot and repository root as independently maintained versions.

`MANIFEST.json` records SHA-256 hashes for every handoff payload file, excluding the manifest itself. Check hashes after transfer; hashes prove file identity, not in-game correctness.

## Build and verified checks

From the repository root, or from the portable `source-snapshot/` directory:

```sh
python3 build-neoperro.py
python3 tests/run-lua.py tests/core.spec.lua tests/runtime.spec.lua
```

Python and the **Lua 5.4 shared library** are required (the runner uses Python ctypes, not a Lua command-line executable). Both assertion suites passed in the cloud. The generated runtime is executed in replacement regressions; generated/config files also receive syntax checks. The build was repeated with identical outputs. Native Windows dependency discovery may differ; diagnose the actual runner environment rather than replacing a meaningful test with syntax alone.

The full bundle is updated. `neoperro.lua` retains config at the top and its runtime loader at the bottom, but downloads **main**, which still has the older runtime. For local live testing use this handoff's `source-snapshot/neoperro-full.lua` and confirm runtime version `1.2.0` before interpreting results.

Your current IDs remain internal: Da Strike `134196333708867`, Da Uphill `71324444457408`, Da Downhill `139144803593140`. Looten's IDs are old; keep using its relevant implementation with these current IDs.
