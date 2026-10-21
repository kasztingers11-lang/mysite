# neoperro — Codex handoff

This package preserves the current source snapshot, four user-supplied screenshots, requested behavior, reported failures, and a proposed repair plan as of 2026-10-21.

**The current build is reported broken in-game. The proposed repairs have not been implemented or verified.** Older documentation in `source-snapshot/NEOPERRO.md` describes v1.1 intentions and is superseded by the requirements here where they conflict.

- [Requested behavior and feature explanations](docs/REQUIREMENTS.md)
- [Reported bugs, proposed fixes, and acceptance checks](docs/BUGS-AND-FIXES.md)
- [Screenshots and interpretation](docs/IMAGES.md)
- [Looten reuse requirement and source evidence](docs/LOOTEN.md)
- `source-snapshot/`: existing scripts, editable modules, build script, and mock tests.
- `references/`: supplied Looten and Goodnight reference snapshots. Inclusion does not establish ownership or a license.

## Start here in Codex

Read the four documents above before changing code. Compare the editable source with Looten rather than assuming the previous build works. Preserve the configuration-first loader and all requested features. Track each repair against the bug list. Do not pad the source to a line count or claim live Roblox verification from mocked tests.

Original project: https://github.com/kasztingers11-lang/mysite

Last published version recorded in the conversation: `a669543c6bf5a28d62b69133554abd8b5e61855a` (v1.1). This package contains the files available in the conversation workspace; it is not a fresh checkout of that commit.

## Build and verification

From `source-snapshot`, run `python build-neoperro.py`, then `python tests/run-lua.py tests/core.spec.lua tests/runtime.spec.lua` if the required Lua runtime is available. Existing tests are included as historical development tools. They were not rerun while preparing this handoff and do not prove game compatibility.

Actual shot acceptance, input behavior, visuals, and feature interactions require in-game testing. Record the game, weapon, configuration, runtime version, observed behavior, and error output with each result.
