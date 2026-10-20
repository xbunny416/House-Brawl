# Store art (icon + thumbnail)

`scene.html` is a three.js scene (Roblox-style blocky fighters, studs, lighting, shadows, bloom) with the title drawn
on top; `render.mjs` opens it in headless Chromium and saves two screenshots.

```sh
cd tools/store-art
npm install
mkdir -p out && node render.mjs out        # out/thumbnail.png (1920x1080) and out/icon-1024.png
# the icon is icon-1024.png scaled down to 512x512 (Pillow: Image.resize((512, 512), Image.LANCZOS))
```

`render.mjs` expects Chromium at `/opt/pw-browsers/chromium-1194/chrome-linux/chrome`; change `executablePath` if yours
is elsewhere. The finished files are in `docs/store/`. Change colors, poses or camera in `scene.html` and re-render.
