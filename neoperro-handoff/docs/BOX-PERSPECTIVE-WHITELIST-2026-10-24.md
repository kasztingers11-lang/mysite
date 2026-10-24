# 1.3.21 character-relative boxes and online whitelist - 2026-10-24

## Clarified box behavior

The user's new screenshot shows the problem with the previous interpretation:
near and distant targets have similarly sized screen rectangles, although their
visible bodies differ greatly. The earlier live v1.3.19 capture also measured a
constant 96x88-pixel native Drawing across 3.059-187.628 studs. Those measurements
are compatible with the screenshot. They do not mean the user's intended box
coverage was correct. Fixed screen pixels made far-target coverage much larger
relative to the body. The fixed-pixel interpretation in 1.3.18-1.3.20 is superseded.

ESP and all box selection now share fixed Width/Height around the root, projected
using camera depth and vertical FieldOfView. Near characters and their boxes grow
together; distant characters and boxes shrink together. Existing 5x4.3 values
stay unchanged. Size does not fit animated limbs or interpolate toward a target.
The focal length is cached until viewport height or vertical FOV changes, adding
no per-player projection calls. Circle radii retain their existing pixel units.

Gun Specifications selects configured dimensions immediately at physical
local-player-to-target range boundaries: <=Close, <=Medium, <=Far, then base.
Perspective follows camera depth separately from range selection. Disabled gun
profiles always use the base dimensions. ESP and targeting use the same result.

## Whitelist departure repair

Target/Friend filtering now uses only assigned IDs currently in the server.
PlayerAdded/PlayerRemoving invalidate cached membership; this does not scan all
players for every target or frame. When the last online assigned player leaves,
Silent, Assist and Triggerbot allow other eligible players again. Saved IDs stay
in the configuration/session roster and resume filtering if that user rejoins.
Respawning in the same server does not remove an assignment. Existing assignment
controls, no assignment cap, and independent checks remain.

## Verification and limits

- Core/runtime suites pass. Projection checks cover relative character coverage
  across depth, FOV and viewport changes; behind-camera rejection; unchanged limb
  dimensions; instant forward/reverse gun range crossings; all configured weapons;
  disabled/unlisted profiles; and matching rendered/selection rectangles.
- Whitelist fixtures cover all three features in Friend and Target modes, last
  departure before Parent changes, offline-only startup, unchanged table reapply,
  and returning assigned users. Saved IDs remain intact.
- The complete runtime suite also passes through the actual protected upload with
  mocked signed grants and hashing. Guard rejection and warm-loader checks pass.
- REAL static analysis reports zero errors/warnings for the full bundle and the
  upload. For the latter, a provider-variable declaration was prefixed only to
  analyzer input, never to the release artifact; it grants no authorization.
- The 1.3.20 early box rejection, hidden-drawing fast paths and TB/Silent cooperation
  remain under regression. No FPS target or live performance gain is claimed.

No new live game execution, shot result, screenshot capture or provider login was
performed for 1.3.21. The screenshot is user-supplied evidence, not an assistant
live measurement. Source/mocks/static checks do not prove Roblox compatibility.
FlowAuth must receive the new protected upload before changing the website bridge
from production 1.3.20 to 1.3.21. No private key or full private table was read.
