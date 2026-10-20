"""Generates the Brawl Arena store art: icon (512x512) and thumbnail (1920x1080).
Usage: python3 -I tools/store-art/make_art.py <output dir>   (needs Pillow; fonts: Inter, see FONT_DIR)
All artwork is drawn from shapes here: no outside assets."""
import math
import random
import sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

FONT_DIR = "/usr/share/fonts/opentype/inter/"
TITLE_FONT = FONT_DIR + "Inter-BlackItalic.otf"

ORANGE = (232, 116, 52)
RUST = (200, 100, 45)
PINK = (217, 140, 154)
TEAL = (47, 140, 140)
CREAM = (245, 236, 214)
YELLOW = (255, 214, 64)
DARK = (28, 22, 34)
ASPHALT = (74, 74, 79)
NEON_PINK = (255, 79, 163)
NEON_TEAL = (63, 242, 224)
TOXIC = (57, 255, 136)
RED = (226, 64, 52)
SKIN = (255, 204, 153)

SS = 2  # supersampling


def font(size):
    return ImageFont.truetype(TITLE_FONT, int(size))


def gradient(w, h, top, bottom):
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = c
    return img


def sunburst(img, center, colors, rays=22):
    w, h = img.size
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    r = math.hypot(w, h)
    step = 2 * math.pi / rays
    for i in range(rays):
        if i % 2:
            continue
        a0, a1 = i * step, (i + 1) * step
        d.polygon([center, (center[0] + r * math.cos(a0), center[1] + r * math.sin(a0)),
                   (center[0] + r * math.cos(a1), center[1] + r * math.sin(a1))], fill=colors)
    img.alpha_composite(overlay) if img.mode == "RGBA" else img.paste(overlay, (0, 0), overlay)


def starburst(d, center, r_out, r_in, points, fill, outline, width):
    pts = []
    for i in range(points * 2):
        r = r_out if i % 2 == 0 else r_in
        a = math.pi * i / points - math.pi / 2
        jitter = 1 + 0.08 * math.sin(i * 7.3)
        pts.append((center[0] + r * jitter * math.cos(a), center[1] + r * jitter * math.sin(a)))
    d.polygon(pts, fill=fill, outline=outline, width=width)


def outlined_text(img, text, xy, size, fill, outline, outline_w, slant=-0.18, shadow=(0, 0), anchor="mm", shadow_fill=DARK):
    """Slanted text with a thick outline and an optional hard drop shadow."""
    f = font(size)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    if shadow != (0, 0):
        d.text((xy[0] + shadow[0], xy[1] + shadow[1]), text, font=f, fill=shadow_fill, anchor=anchor,
               stroke_width=outline_w, stroke_fill=shadow_fill)
    d.text(xy, text, font=f, fill=fill, anchor=anchor, stroke_width=outline_w, stroke_fill=outline)
    # shear around the text centre
    cx, cy = xy
    layer = layer.transform(layer.size, Image.AFFINE, (1, slant, -slant * cy, 0, 1, 0), Image.BICUBIC)
    img.alpha_composite(layer)


def glow(img, draw_fn, color, radius):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw_fn(ImageDraw.Draw(layer), color)
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(radius)))
    img.alpha_composite(layer)


def block(d, box, fill, outline=DARK, w=6, r=10):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=w)


def fighter(d, x, y, s, shirt, pants, facing, pose):
    """A blocky brawler. (x, y) = feet centre, s = scale. pose: 'punch' | 'fly' | 'stand'. facing = +1 right / -1 left."""
    w = max(3, int(5 * s))
    leg_w, leg_h = 34 * s, 62 * s
    torso_w, torso_h = 78 * s, 84 * s
    head = 62 * s
    top_legs = y - leg_h
    top_torso = top_legs - torso_h
    # legs
    spread = 14 * s if pose != "fly" else 30 * s
    block(d, (x - spread - leg_w / 2, top_legs, x - spread + leg_w / 2, y), pants, w=w, r=int(6 * s))
    block(d, (x + spread - leg_w / 2, top_legs, x + spread + leg_w / 2, y - (0 if pose != "fly" else 14 * s)), pants, w=w, r=int(6 * s))
    # back arm
    arm_w, arm_h = 30 * s, 72 * s
    back_x = x - facing * (torso_w / 2 + arm_w / 2 - 4 * s)
    block(d, (back_x - arm_w / 2, top_torso + 6 * s, back_x + arm_w / 2, top_torso + 6 * s + arm_h), SKIN, w=w, r=int(6 * s))
    # torso
    block(d, (x - torso_w / 2, top_torso, x + torso_w / 2, top_legs + 4 * s), shirt, w=w, r=int(8 * s))
    # head
    block(d, (x - head / 2, top_torso - head + 4 * s, x + head / 2, top_torso + 4 * s), SKIN, w=w, r=int(12 * s))
    ex = x + facing * 10 * s
    d.ellipse((ex - 6 * s, top_torso - head * 0.55, ex + 6 * s, top_torso - head * 0.55 + 12 * s), fill=DARK)
    d.line((ex - 12 * s, top_torso - head * 0.7, ex + 12 * s, top_torso - head * 0.62 + (0 if facing > 0 else 0)), fill=DARK, width=max(2, int(5 * s)))
    # front arm
    if pose == "punch":
        reach = 150 * s
        sx = x + facing * torso_w / 2
        sy = top_torso + 30 * s
        ex2 = sx + facing * reach
        block(d, (min(sx, ex2), sy - arm_w / 2, max(sx, ex2), sy + arm_w / 2), SKIN, w=w, r=int(6 * s))
        fist = 52 * s
        fx = ex2 + facing * fist / 2 - facing * 6 * s
        block(d, (fx - fist / 2, sy - fist / 2, fx + fist / 2, sy + fist / 2), RED, w=w, r=int(10 * s))
    else:
        front_x = x + facing * (torso_w / 2 + arm_w / 2 - 4 * s)
        up = pose == "fly"
        if up:
            block(d, (front_x - arm_w / 2, top_torso - 40 * s, front_x + arm_w / 2, top_torso + 30 * s), SKIN, w=w, r=int(6 * s))
        else:
            block(d, (front_x - arm_w / 2, top_torso + 6 * s, front_x + arm_w / 2, top_torso + 6 * s + arm_h), SKIN, w=w, r=int(6 * s))


def platform(d, cx, top, width, depth, thick, color, side):
    """A chunky floating slab seen from the front-top."""
    x0, x1 = cx - width / 2, cx + width / 2
    # top face: back edge narrower than the front edge (perspective), then the thick front side
    d.polygon([(x0 + depth * 0.6, top), (x1 - depth * 0.6, top), (x1, top + depth), (x0, top + depth)],
              fill=tuple(min(255, c + 25) for c in color), outline=DARK, width=max(2, int(depth / 14)))
    d.polygon([(x0, top + depth), (x1, top + depth), (x1, top + depth + thick), (x0, top + depth + thick)],
              fill=side, outline=DARK, width=max(2, int(depth / 14)))
    d.line([(x0 + depth * 0.3 + 10, top + depth * 0.5), (x1 - depth * 0.3 - 10, top + depth * 0.5)], fill=YELLOW,
           width=max(3, int(depth / 12)))


def thumbnail(path):
    W, H = 1920 * SS, 1080 * SS
    img = gradient(W, H, (255, 150, 80), (214, 96, 122)).convert("RGBA")
    # sun + rays
    sunburst(img, (W * 0.5, H * 0.62), (255, 235, 190, 46), rays=30)
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse((W * 0.5 - 260 * SS, H * 0.62 - 260 * SS, W * 0.5 + 260 * SS, H * 0.62 + 260 * SS), fill=(255, 230, 160, 140))
    # toxic glow from below
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_layer)
    gd.rectangle((0, H * 0.9, W, H), fill=TOXIC + (200,))
    img.alpha_composite(glow_layer.filter(ImageFilter.GaussianBlur(70 * SS)))
    # distant floating chunks
    random.seed(7)
    for _ in range(9):
        x = random.randint(0, W)
        y = random.randint(int(H * 0.5), int(H * 0.9))
        w = random.randint(60, 150) * SS
        d.rounded_rectangle((x, y, x + w, y + 22 * SS), radius=8 * SS, fill=(120, 60, 80, 210))
    # main platforms
    platform(d, W * 0.5, H * 0.68, 1100 * SS, 110 * SS, 70 * SS, ASPHALT, (52, 52, 58))
    platform(d, W * 0.13, H * 0.8, 380 * SS, 60 * SS, 40 * SS, (150, 144, 134), (96, 92, 86))
    platform(d, W * 0.88, H * 0.78, 360 * SS, 60 * SS, 40 * SS, (150, 144, 134), (96, 92, 86))
    # fighters
    base_y = H * 0.68 + 110 * SS * 0.6
    fighter(d, W * 0.36, base_y, 1.55 * SS, TEAL, (40, 60, 90), +1, "punch")
    fighter(d, W * 0.84, H * 0.50, 1.45 * SS, NEON_PINK, (60, 40, 70), -1, "fly")
    # speed lines behind the launched fighter
    for i in range(6):
        y = H * 0.30 + i * 34 * SS
        d.line([(W * 0.69 - i * 4 * SS, y), (W * 0.77, y + 14 * SS)], fill=(255, 255, 255, 190), width=6 * SS)
    # POW burst at the punch
    starburst(d, (W * 0.60, H * 0.555), 165 * SS, 88 * SS, 11, YELLOW, DARK, 9 * SS)
    outlined_text(img, "POW!", (W * 0.60, H * 0.555), 96 * SS, RED, CREAM, 8 * SS, slant=-0.15)
    # title
    outlined_text(img, "BRAWL", (W * 0.5, H * 0.105), 215 * SS, CREAM, DARK, 15 * SS, shadow=(0, 13 * SS))
    outlined_text(img, "ARENA", (W * 0.5, H * 0.250), 215 * SS, YELLOW, DARK, 15 * SS, shadow=(0, 13 * SS))
    # tagline ribbon
    ribbon = (W * 0.5 - 520 * SS, H * 0.865, W * 0.5 + 520 * SS, H * 0.865 + 96 * SS)
    d.rounded_rectangle(ribbon, radius=16 * SS, fill=DARK, outline=NEON_TEAL, width=6 * SS)
    outlined_text(img, "KNOCK THEM OFF THE EDGE!", ((ribbon[0] + ribbon[2]) / 2, (ribbon[1] + ribbon[3]) / 2), 56 * SS,
                  NEON_TEAL, DARK, 2 * SS, slant=-0.12)
    img = img.resize((1920, 1080), Image.LANCZOS).convert("RGB")
    img.save(path, quality=92)


def icon(path):
    S = 512 * SS
    img = gradient(S, S, (255, 140, 70), (206, 82, 120)).convert("RGBA")
    sunburst(img, (S * 0.5, S * 0.52), (255, 235, 190, 60), rays=24)
    d = ImageDraw.Draw(img, "RGBA")
    # toxic glow bottom
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow_layer).rectangle((0, S * 0.93, S, S), fill=TOXIC + (230,))
    img.alpha_composite(glow_layer.filter(ImageFilter.GaussianBlur(24 * SS)))
    # platform
    platform(d, S * 0.5, S * 0.72, 440 * SS, 46 * SS, 28 * SS, ASPHALT, (52, 52, 58))
    # fighters (punch, launched)
    fighter(d, S * 0.26, S * 0.72 + 30 * SS, 0.70 * SS, TEAL, (40, 60, 90), +1, "punch")
    fighter(d, S * 0.86, S * 0.56, 0.60 * SS, NEON_PINK, (60, 40, 70), -1, "fly")
    starburst(d, (S * 0.64, S * 0.60), 62 * SS, 34 * SS, 10, YELLOW, DARK, 5 * SS)
    outlined_text(img, "POW!", (S * 0.64, S * 0.60), 32 * SS, RED, CREAM, 4 * SS, slant=-0.15)
    outlined_text(img, "BRAWL", (S * 0.5, S * 0.10), 104 * SS, CREAM, DARK, 9 * SS, shadow=(0, 6 * SS))
    outlined_text(img, "ARENA", (S * 0.5, S * 0.245), 104 * SS, YELLOW, DARK, 9 * SS, shadow=(0, 6 * SS))
    img = img.resize((512, 512), Image.LANCZOS).convert("RGB")
    img.save(path)


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    thumbnail(out + "/brawl-arena-thumbnail-1920x1080.png")
    icon(out + "/brawl-arena-icon-512.png")
    print("done")
