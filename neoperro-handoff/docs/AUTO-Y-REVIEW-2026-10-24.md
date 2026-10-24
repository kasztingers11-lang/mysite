# Auto Y review - 2026-10-24 - 1.3.16

The user requested a 20-minute improvement pass. Work began at 06:13:54 UTC
(08:13:54 Europe/Berlin). This is offline source, regression, replay and static
analysis. The instruction not to inject remains active; no live game interaction
or customer/executor credential collection occurred.

## Reproduced issues and changes

- **Apex erased by stale floor state.** Auto Y still used a non-Air FloorMaterial
  to mark a near-zero-Y target grounded. The new regression recreates a measured
  ballistic apex while that property says Plastic. The old implementation removes
  the vertical forecast; the new one preserves it. FloorMaterial is diagnostic.
- **Future support confused with current contact.** The old support ray originated
  at predicted XZ. A raised surface ahead could classify the current airborne
  player as grounded. Current-footprint contact now supplies grounding; predicted
  support remains the independent landing minimum. One additional short current
  probe is used only when Auto grounding needs it, the vertical speed is near
  rest, and the horizontal origins differ. Coincident origins reuse the first ray.
- **Grounded ramps flattened.** Low world-Y motion on a slope was forced to zero.
  When current and future hits are on the same continuous plane, measured height
  change can supply bounded support-follow lead. Surface identity, matching normals
  and plane agreement are required. Equal normals at separate raised heights do
  not qualify, so this does not add a generic upward offset. Unknown/discontinuous
  support retains the conservative existing contact behavior.
- **Mixed velocity sources.** TrueVelocity could correct Y from position history,
  while Auto Y attached acceleration measured from the rejected raw Y. That
  synthetic constant-climb case produced extra lead. Corrected Y now uses linear
  resolved motion instead. Diagnostics distinguish measured raw acceleration,
  actually applied acceleration and the vertical model source.
- **Sampling-phase confidence loss.** A live velocity was compared only with the
  regression at the latest history timestamp. Between history samples, coherent
  acceleration could lose confidence and disappear. The fit now validates the
  velocity interval from the last sample to the current read, bounded to 50 ms.
  Held and updated velocities both fit that interval. This is an uncertainty
  envelope, not extra replication age or added prediction time. Stale fits reject.

## Validation

Core/runtime/protected suites pass. New cases cover all three feature forecasts,
four apex sampling phases, future raised support, +/-X and +/-Z ramps, discontinuous
steps, resolved/raw acceleration isolation and 30/60/144/240 sampling schedules.
Existing apex/fall/braking, impulse rejection, ground clamps, rotated pose heights,
feature routing and cleanup checks remain passing. Auto ignores Offset; Custom
keeps its separate positive-lead multiplier. No table values or names changed.

An independent idealized replay compares the previous committed Core with this
version over 1,452 forecast cases: three measured accelerations, four sampling/
render schedules and four horizons (.05/.1/.2/.35 seconds). Reference displacement
is the analytical quadratic with the same existing part-height bounds. At modeled
144/240 FPS, the old sampling-phase calculation had mean errors .3701/.4367 studs,
with a 10.69375-stud worst case; the revised replay agrees within 3.6e-14 studs.
30/60 schedules were already within numerical precision. These figures isolate
this mathematical defect under exact input; they are not replication or hit-rate
measurements and do not establish accuracy with noisy/unobserved future movement.
Exact replay data is embedded in the release VALIDATION.json. Reproduce with
`python tests/auto-y-replay.py --baseline-ref 641ae2d65380c4e70cfeb57d486bfc3db85268c9`
in a clone containing the preceding published commit. The local baseline 4d9520a
has the same Core source as that public 1.3.15 commit.

Full/runtime/starter/protected REAL analyzers each report zero errors/warnings.
The protected checker declares a synthetic grant for analysis only; protected
regressions use mock authorization/hash primitives. No FlowAuth login or published
provider-produced output was tested. No final Roblox injection occurred.

## Evidence and limits

Roblox marks [Humanoid.FloorMaterial](https://create.roblox.com/docs/reference/engine/classes/Humanoid)
not replicated and documents rig-specific HipHeight formulas. Its
[raycasting documentation](https://create.roblox.com/docs/workspace/raycasting)
also explains that unstreamed client geometry may not produce a hit. Consequently,
a missing support ray is not a claim of authoritative server airborne state.
GroundContact diagnostics separate current probe/clearance, predicted surface,
rig support height and continuous-plane lead; FloorMaterial remains separately
recorded. AppliedVerticalAcceleration and VerticalModelSource explain which
vertical model actually supplied the coordinates.

Still needed after fresh live authorization: remote ascent/apex/fall/landing,
high-ping diagonal motion, slopes and weapon/obstacle shots with actual damage
attribution. Moving/rotating platforms, changing/curved surfaces, network-staircase
updates and streamed-out geometry are not validated by the idealized replay.
Existing conservative lead bounds remain; no perfect-prediction, guaranteed hit,
fixed FPS or Roblox-compatibility claim is made. Custom and independent ground
checks remain user controls. No new settings, constant upward offset, assumed
gravity or invented bullet speed were introduced.
