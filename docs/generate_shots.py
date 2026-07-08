#!/usr/bin/env python3
# Generates product shots for Papertone by rendering each preset's exact
# overlay + gamma math onto a clean "reading app" mock. Faithful to the app.
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = sys.argv[1]  # docs directory
W, H = 1600, 1000

def font(sz, bold=False):
    for p in ["/System/Library/Fonts/Helvetica.ttc",
              "/System/Library/Fonts/Supplemental/Arial.ttf"]:
        try:
            return ImageFont.truetype(p, sz)
        except Exception:
            pass
    return ImageFont.load_default()

# ---- Presets (mirror Shared/Presets.swift) ----
# tint(rgb 0-1), tintAlpha, grainAlpha, vignette, warmth, contrast, blackLift, whiteDrop
PRESETS = [
    ("Classic Matte",      (0.94,0.94,0.92), 0.18, 0.05, 0.00, 0.00, 0.00, 0.00, 0.00),
    ("Sunbaked Parchment", (0.98,0.90,0.76), 0.26, 0.09, 0.05, 0.15, 0.00, 0.00, 0.00),
    ("Sepia",              (0.76,0.60,0.42), 0.30, 0.05, 0.08, 0.20, 0.00, 0.03, 0.00),
    ("Night Warm",         (1.00,0.85,0.60), 0.05, 0.00, 0.00, 0.70, 0.00, 0.00, 0.05),
    ("Faded Film",         (0.95,0.94,0.90), 0.08, 0.10, 0.12, 0.12, 0.00, 0.10, 0.06),
    ("Vivid Punch",        (1.00,1.00,1.00), 0.00, 0.00, 0.00, 0.00, 0.50, 0.00, 0.00),
]
INTENSITY = 0.62

def draw_base():
    """A clean, bright writing/reading app — the harsh white the app tames."""
    img = Image.new("RGB", (W, H), (250, 250, 251))
    d = ImageDraw.Draw(img)
    # Top toolbar
    d.rectangle([0, 0, W, 60], fill=(237, 237, 240))
    for i, c in enumerate([(255,95,86),(255,189,46),(39,201,63)]):
        d.ellipse([24+i*26, 22, 40+i*26, 38], fill=c)
    d.text((W//2-70, 20), "papertone.md", font=font(20), fill=(120,120,125))
    # Sidebar
    d.rectangle([0, 60, 250, H], fill=(244, 244, 247))
    for i in range(7):
        y = 96 + i*54
        d.rounded_rectangle([28, y, 222, y+30], radius=8,
                            fill=(228,228,233) if i != 1 else (210,214,244))
    # Content
    cx = 300
    d.text((cx, 104), "Reading, easier on the eyes", font=font(40, True), fill=(28,28,30))
    d.text((cx, 168), "How a warm paper tone reduces glare", font=font(24), fill=(150,150,155))
    y = 240
    for _ in range(9):
        w = W - cx - 90 - (60 if _ % 3 == 2 else 0)
        d.rounded_rectangle([cx, y, w, y+16], radius=6, fill=(222,222,227))
        y += 42
    # A bright card (where glare is worst)
    d.rounded_rectangle([cx, y+16, W-90, H-70], radius=16, fill=(255,255,255),
                        outline=(232,232,236), width=2)
    d.text((cx+28, y+44), "The brightest whites get the warmest treatment.",
           font=font(22), fill=(90,90,95))
    return img

def gamma_luts(warmth, contrast, black_lift, white_drop, intensity):
    warmth *= intensity; contrast *= intensity
    lo = black_lift * intensity * 0.12
    hi = 1.0 - white_drop * intensity * 0.10
    bs = 1.0 - 0.45 * warmth
    gs = 1.0 - 0.12 * warmth
    lr, lg, lb = [], [], []
    for i in range(256):
        x = i / 255.0
        s = x * x * (3 - 2 * x)
        v = x * (1 - contrast) + s * contrast
        v = lo + v * (hi - lo)
        clamp = lambda z: int(max(0, min(1, z)) * 255)
        lr.append(clamp(v)); lg.append(clamp(v * gs)); lb.append(clamp(v * bs))
    return lr, lg, lb

def apply_look(base, p):
    _, tint, tA, gA, vig, warmth, contrast, blk, wht = p
    work = base.convert("RGBA")
    # Tint wash
    if tA > 0:
        tc = (int(tint[0]*255), int(tint[1]*255), int(tint[2]*255), int(tA*INTENSITY*255))
        work = Image.alpha_composite(work, Image.new("RGBA", (W, H), tc))
    # Grain
    if gA > 0:
        noise = Image.effect_noise((W, H), 26).convert("L")
        alpha = Image.new("L", (W, H), int(gA*INTENSITY*255))
        work = Image.alpha_composite(work, Image.merge("RGBA", [noise, noise, noise, alpha]))
    # Vignette
    if vig > 0:
        mask = Image.radial_gradient("L").resize((W, H))
        mask = mask.point(lambda z: int(z * vig * INTENSITY))
        black = Image.new("RGBA", (W, H), (0, 0, 0, 0)); black.putalpha(mask)
        work = Image.alpha_composite(work, black)
    # Gamma curve (applied to the whole framebuffer at scanout)
    rgb = work.convert("RGB")
    lr, lg, lb = gamma_luts(warmth, contrast, blk, wht, INTENSITY)
    r, g, b = rgb.split()
    return Image.merge("RGB", [r.point(lr), g.point(lg), b.point(lb)])

def label(img, text):
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([0, img.height-46, img.width, img.height], fill=(0,0,0,150))
    d.text((16, img.height-38), text, font=font(22, True), fill=(255,255,255))
    return img

base = draw_base()

# --- Hero: before / after split ---
after = apply_look(base, PRESETS[1])  # Sunbaked Parchment
hero = Image.new("RGB", (W, H))
hero.paste(base.crop((0,0,W//2,H)), (0,0))
hero.paste(after.crop((W//2,0,W,H)), (W//2,0))
d = ImageDraw.Draw(hero, "RGBA")
d.line([(W//2,0),(W//2,H)], fill=(255,255,255,220), width=3)
for x, t in [(40,"Without Papertone"), (W//2+40,"With Papertone")]:
    d.rectangle([x-14, 30, x+len(t)*12+14, 70], fill=(0,0,0,150))
    d.text((x, 38), t, font=font(24, True), fill=(255,255,255))
hero.save(f"{OUT}/hero.png")

# --- Preset grid 3x2 ---
tw, th, gap, pad = 500, 313, 18, 24
gw = pad*2 + tw*3 + gap*2
gh = pad*2 + th*2 + gap
grid = Image.new("RGB", (gw, gh), (18, 18, 20))
for i, p in enumerate(PRESETS):
    tile = label(apply_look(base, p).resize((tw, th)), p[0])
    r, c = divmod(i, 3)
    grid.paste(tile, (pad + c*(tw+gap), pad + r*(th+gap)))
grid.save(f"{OUT}/presets.png")
print("wrote hero.png and presets.png")
