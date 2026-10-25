# PolSec upload migration - 2026-10-25

The owner requested migration from FlowAuth to PolSec. The prepared upload is
neoperro-polsec-upload.obfuscated.lua in releases/neoperro-1.3.22-polsec, outside Git.
It reuses the exact tested native payload from v1.3.22, checks its SHA-256 and sets
Distribution=PolSec. The FlowAuth-only LRM_IsUserPremium gate is absent. No PolSec
client grant name was guessed: PolSec's generated loader/protected delivery is
responsible for authentication. No table, license key or external loader is baked
into the upload. New PolSec execution replaces an active FlowAuth runtime cleanly;
matching PolSec payloads can reuse ApplyConfig.

Reproduce with build-polsec.py --from-release ../releases/neoperro-1.3.22.
The builder verifies both readable source and native payload hashes before wrapping.
The existing FlowAuth build/site stay available until the replacement loader exists.

Checks: PolSec wrapper cold load, same-provider reuse, foreign-provider replacement,
tampered payload, missing hash and compile failure pass. The complete runtime mock
suite passes through the PolSec upload, including native TB/Silent timing, config
updates, inputs, prediction, visuals and cleanup. Official Luau 0.744 compilation
and REAL static analysis pass (zero errors/warnings; no provider declaration needed).
These are not PolSec authorization, provider-obfuscation or native gameplay results.
The gameplay payload/hash itself is unchanged from the FlowAuth release.

The user showed Auto Macro's UI description: it skips virtualization for hot
callbacks/hooks/scan loops. Recommended on for frequent aiming/render work, based
on that description. No native provider-performance result is claimed.

Next: owner uploads/publishes this file and supplies the GENERATED PUBLIC loader
URL (project/script identifiers, not an API key). Then prepare the Fosternya bridge
for PolSec, preserve script_key plus the edited table, run provider-specific bridge
mocks, deploy and verify. Until then production Fosternya still loads FlowAuth.
Do not claim the website/provider migration is complete or that existing FlowAuth
customer keys automatically work with PolSec.

Primary provider reference: https://polsec.sh/docs/api-reference/status/service-status
(search indexed documentation supplied upload/generated-loader integration; direct
page fetch returned HTTP 502). No account API key or license key was requested/read.
