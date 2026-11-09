# Neoperro intro preview

The intro uses two bundled transparent PNGs, the Highcrest wordmark from the site and a smooth red eye graphic. The eyes open above the wordmark and close before the world fades back in. The scene blur eases in and out with the dimming layer.

```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/kasztingers11-lang/mysite/repair/neoperro-intro-v2/neoperro-intro/preview.lua'))()
```

The artwork needs no HTTP download at runtime. The preview uses local asset registration when available and native UI shapes and text if the images cannot load in time. The existing meow loads independently. When the intro ends, it removes its own GUI, blur and sound.
