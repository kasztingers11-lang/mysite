# Protected distribution build

Based on Prometheus by Elias Oelschner, https://github.com/prometheus-lua/Prometheus

The build pins commit `a4efc5f381c50ae2a111bdbb9272fa3203685be3`. Prometheus uses
its own MIT-style license with an attribution condition; its license is in the
upstream checkout. This project does not vendor the obfuscator.

Rebuild the runtime with `build-neoperro.py`, then run `build-protected.py` with
`--prometheus` pointing to that checkout. Python requires Lupa's Lua 5.1 backend.
Outputs default to the sibling `releases/neoperro-1.3.12/` directory, outside Git.

- `neoperro-flowauth-upload.obfuscated.lua`: upload this runtime to your FlowAuth script.
- `neoperro-flowauth.lua`: editable placeholder key, full table, and your public loader.
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

The starter already contains the supplied public loader hash. Put your real key
only into your private local copy when running it. Never commit or send that key.
Do not upload the starter as the protected runtime: its editable table belongs
before the loader. No key, API token or webhook secret belongs in the upload.

Public Git history already contains readable development runtimes. This build
does not revoke those copies or make the existing public source a licensed-only
product. Restrict future source distribution separately before selling access.

## Validation for this build

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
