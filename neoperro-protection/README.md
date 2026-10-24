# Protected distribution build

Based on Prometheus by Elias Oelschner, https://github.com/prometheus-lua/Prometheus

The build pins commit `a4efc5f381c50ae2a111bdbb9272fa3203685be3`. Prometheus uses
its own MIT-style license with an attribution condition; its license is in the
upstream checkout. This project does not vendor the obfuscator.

Rebuild the runtime with `build-neoperro.py`, then run `build-protected.py` with
`--prometheus` pointing to that checkout. Python requires Lupa's Lua 5.1 backend.
Outputs default to the sibling `releases/neoperro-1.3.16/` directory, outside Git.

- `neoperro-flowauth-upload.obfuscated.lua`: upload this runtime to your FlowAuth script.
- `neoperro-flowauth.lua`: editable placeholder key, full table, and your public loader.
- `neoperro-flowauth-loader.lua`: replace only the old bottom loader in your private edited starter.
- `neoperro-native.obfuscated.lua`: local test payload; do not distribute as a loader.
- `BUILD.json`: source/output digests, sizes and build settings. Contains no keys.

The AST pipeline renames locals, encrypts strings and shuffles constants. Frame
callbacks remain native Lua functions. Numeric output uses 17 significant digits
to preserve large exact IDs and generated cipher seeds. No VM interpreter or
debug-hook/line-number/busy-loop anti-tamper pass is used.

The upload checks FlowAuth's bare `LRM_IsUserPremium` grant, hashes its obfuscated
payload with SHA-256 and stops with an error before compilation if integrity
fails. It requires `crypt.hash(data, 'sha256')` and `loadstring`; REAL provides both.
The hash is not a secret or digital signature. A determined client owner can
remove checks or instrument execution; this cannot guarantee prevention of
deobfuscation. The provider's authenticated delivery is the licensing boundary.

In FlowAuth, upload the runtime, require keys, disable keyless access and enable
Auto-obfuscate so the provider protects its signed authorization values and the
bootstrap. Use HWID binding/reset policy through FlowAuth rather than embedding
credentials. The native inner payload avoids adding a VM to every render callback.
Provider builds may behave differently and must be tested after publication.
The grant allows valid free or premium keys; it rejects keyless runs.

Keep your private edited table and key. For an existing starter, replace only its
old bottom loader with the loader-only release file. The complete starter contains
defaults; replacing your entire file with it changes your controls and settings.
The starter already contains the supplied public loader hash. Put your real key
only into your private local copy when running it. Never commit or send that key.
Do not upload the starter as the protected runtime: its editable table belongs
before the loader. No key, API token or webhook secret belongs in the upload.

Public Git history already contains readable development runtimes. This build
does not revoke those copies or make the existing public source a licensed-only
product. Restrict future source distribution separately before selling access.

## Session updates and startup timing

Same-build/distribution starters call ApplyConfig on an alive runtime rather than
fetching, compiling and launching FlowAuth again. This changes the current client
session only. A stopped runtime, different version/distribution or fresh client
uses the normal provider path. The protected entry still requires the provider's
grant before reusing its payload. No real key is cached by this feature.

Invalid configuration is rejected before state mutation. Valid updates release
owned input and reuse listeners, visuals and sampled history. A runtime launched
with an explicit table uses that table even in a full bundle with embedded defaults.
The starter reports download, loader-compile and loader-return timings. Asynchronous
provider initialization may continue after loader return; that number is not a
complete provider startup measurement.

## Validation for 1.3.16

Core/runtime/protected regressions pass. Coverage includes off-center camera/cursor
alignment, all eight Silent/Assist/Triggerbot combinations, FOV-off character tests,
50 repeated table updates, unlimited IDs/assignments, posture transitions and ESP
tags. Added tests cover predicted XYZ Closest Point, 18 rotated-part/manual/Auto
feature cases and 18 exact Raycast cases, observed acute turns/braking, one support
query per selection and held-trigger routing. Auto Y adds current/future footprint, stale floor state, continuous ramps,
resolved/raw acceleration isolation and 30/60/144/240 sampling-phase regressions.
The protected suite uses synthetic grants and hashing, not FlowAuth auth.
Full, runtime, readable starter and protected upload pass REAL static analysis with
zero errors/warnings. The final collision fix has not been injected/live tested,
following the user's instruction to work offline. Provider publication remains
untested. Mocks and static checks do not establish Roblox compatibility or hit rate.

## Historical 1.3.12 native validation

The complete runtime mock suite passed against the obfuscated upload with a
synthetic grant and hash backend. Guard tests deny four invalid/missing grant
values, a changed payload and missing hash support before payload compilation;
compile rejection and the successful integrity path also pass. Starter comments
were checked to preserve every authoritative configuration value.

REAL analysis reports zero errors/warnings with the provider grant declared by
the local fixture. Native tests rejected a missing grant and a modified payload
while preserving the previously running runtime. The obfuscated runtime then
loaded in Roblox with a separate, local prepublication grant fixture. This is
not a FlowAuth authentication result and the fixture is not a release artifact.

In the empty server, the protected runtime stayed alive with six FOV Drawings;
67,391 aim and drawing updates had matching counts. Mean script aim work was
0.0571 ms and drawing work 0.0277 ms, with no remote records. Later counters
showed six Tool.Activated events and six ammo decreases, zero predicted MOUSE
sends and zero automated trigger attempts. These were not controlled target
shots. No hit accuracy, populated ESP performance or server-grant result is claimed.
Some block-style tool probes timed out; equivalent expression probes succeeded
and the client remained responsive. Their cause was not established. Console
problems remained empty. The ordinary development runtime was restored afterward.

References: [FlowAuth macros and signed grants](https://flowauth.net/docs/macros),
[Prometheus source and license](https://github.com/prometheus-lua/Prometheus).
