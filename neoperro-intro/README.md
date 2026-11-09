# Neoperro intro preview

The in-game intro uses the website wordmark rendered as a transparent PNG from Highcrest. The red eyes open above it, close, and fade out as the game returns to focus. The eyes use native UI geometry derived from the site's artwork, so a crop or image download cannot block them.

```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/kasztingers11-lang/mysite/repair/neoperro-intro-v2/neoperro-intro/preview.lua'))()
```

The preview contains the wordmark image bytes. It uses the executor's local asset registration when available and a readable title if the image cannot load in time. The existing meow is fetched independently and can be skipped if unavailable. The intro removes its own GUI, blur, sound and workers when it ends or is replaced.
