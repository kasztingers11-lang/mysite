# neoperro intro preview

A standalone client intro: the gothic N starts at 8% scale and -225 degrees, swirls smoothly to full size, settles while background blur eases down, then fades away with a slight outward rotation. A thin rectangular card and a short original chime accompany it.

## Preview

```lua
getgenv().neoperroIntroPreview = {
    Duration = 2.2;
    Sound = true;
}

loadstring(game:HttpGet('https://raw.githubusercontent.com/kasztingers11-lang/mysite/main/neoperro-intro/preview.lua'))()
```

The duration is measured after asset loading. It is clamped to 1.4–10 seconds. TweenService uses time-based animation; speed does not depend on a fixed number of frames. The preview does not change the FPS cap and cannot guarantee the client sustains 120 FPS.

## First-run installation

The preview downloads the PNG and Ogg from the immutable asset commit `c639f51026efe14a602368f0dc6865616ccc8a5a`. With the required filesystem functions, it stores them in the executor workspace under:

```text
neoperro/intro-v1/neoperro-n.png
neoperro/intro-v1/neoperro-chime.ogg
```

If folder functions are unavailable, it uses filenames prefixed with `neoperro-intro-v1-` in the workspace root. Existing files with the expected length and file header are reused. Invalid cache files are downloaded again. This is basic format checking, not cryptographic verification.

Required for the full preview: client-side Lua execution, HTTP access, `writefile`, and `getcustomasset` (or the compatible `getsynasset` alias). `readfile` and `isfile` enable cache reuse. `makefolder` and `isfolder` enable the nested cache directory.

`getcustomasset` registers the downloaded file as a content ID that ImageLabel or Sound can load. A normal Roblox LocalScript cannot display an arbitrary GitHub URL as ImageLabel.Image. In Studio, upload the assets to Roblox and adapt the image/sound IDs; without local-asset functions this preview displays a text N and skips unavailable audio.

## Animation and cleanup

- The generated N remains sharp in a ScreenGui while a dedicated BlurEffect changes the 3D scene behind it. This does not blur existing game ScreenGuis. Graphics quality can affect post-processing visibility.
- Assets load concurrently with an eight-second readiness deadline. Failure or timeout allows the intro to continue with a text fallback.
- Re-execution destroys the previous preview before starting the replacement.
- Cleanup cancels owned tweens and worker coroutines, removes the preview GUI and sound, and destroys only this preview's BlurEffect. Other blur effects are left alone; an existing stronger effect may dominate the view.
- The thin line is an animation accent, not a measurement of game loading progress.

## Validation

The Lua source passed mocked lifecycle checks for successful installation, cache reuse on re-execution, replacement during execution, stalled downloads, HTTP failures, and disabled audio. The tests do not render Roblox UI or validate a particular executor. An in-game visual/audio preview remains necessary.

## Sources and rationale

Roblox Developer Forum discussions are useful implementation references; official API documentation defines supported behavior:

- [UI Blurred Background — Developer Forum](https://devforum.roblox.com/t/ui-blurred-background/1088080): applying scene blur behind a GUI.
- [Tweenservice: The ABSOLUTE Basics! — Developer Forum](https://devforum.roblox.com/t/tweenservice-the-absolute-basics-quick-read-6/3666243): tween lifecycle and cancellation.
- [How to put any image on an ImageLabel? — Developer Forum](https://devforum.roblox.com/t/how-to-put-any-image-on-a-imagelabel/3149783): Roblox-hosted image requirements in ordinary scripts.
- [ImageLabel — Creator Hub](https://create.roblox.com/docs/reference/engine/classes/ImageLabel): image content IDs, transparency, and fitting.
- [UI animation — Creator Hub](https://create.roblox.com/docs/ui/animation): time-based UI tweens and CanvasGroup transparency.
- [BlurEffect — Creator Hub](https://create.roblox.com/docs/reference/engine/classes/BlurEffect): blur strength and strongest-effect precedence.
- [getcustomasset — sUNC documentation](https://docs.sunc.io/Filesystem/getcustomasset/): registering local image/audio files.
- [Filesystem — sUNC documentation](https://docs.sunc.io/Filesystem/): the executor workspace and supported filesystem functions.

## Asset provenance

`assets/neoperro-n.png` was created with the built-in image-generation tool. Prompt: a single original uppercase gothic blackletter N, ivory-white strokes, sharp chisel terminals, strong diagonal, balanced negative space, centered with generous padding, transparent background, no other letters, no border or shadow, legible at small intro size.

`assets/neoperro-chime.ogg` is an original 0.9-second synthesized chime built from decaying 440/660/1320 Hz tones, a quiet 110 Hz undertone, and a soft transient, encoded as Ogg Vorbis. The preview plays it at volume 0.22.
