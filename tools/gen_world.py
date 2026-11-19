"""Pixel art světa mimo boj: slumy, bar, úřad a portréty postav.

Volá se z gen_assets.py (sdílí paletu a pomocné funkce). Samostatně:
python3 tools/gen_world.py
"""
from __future__ import annotations

import random

from PIL import Image, ImageDraw, ImageEnhance, ImageOps

import gen_assets as ga
from gen_assets import CLEAR, c, dither, from_ascii, hline, mirror, new, px, rect, save, vline

# Doplňkové barvy zadané hexem (gen_assets je registruje jen ve svém main).
for _hex in ["#4a2d55", "#2a2140", "#5a4a7a", "#3a4a4a", "#7a2050", "#2a1a10", "#6a4a20"]:
    ga.PAL[_hex] = _hex


# --- Pomocné ----------------------------------------------------------------

def outline(img: Image.Image, col: str = "K0") -> Image.Image:
    """Obkreslí neprůhledné pixely 1px obrysem (do průhledných sousedů)."""
    out = img.copy()
    w, h = img.size
    a = img.getchannel("A").load()
    for y in range(h):
        for x in range(w):
            if a[x, y]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and a[nx, ny]:
                    out.putpixel((x, y), c(col))
                    break
    return out


def pad(img: Image.Image, n: int = 1) -> Image.Image:
    out = new(img.width + 2 * n, img.height + 2 * n)
    out.alpha_composite(img, (n, n))
    return out


def draw_text(img, x, y, text, col, scale=1, glow=None):
    """Vykreslí text pixel fontem hry. Vrací šířku v pixelech."""
    cx = x
    for ch in text:
        bm = ga.glyph_bitmap(ch)
        w = len(bm[0])
        for gy, row in enumerate(bm):
            for gx, v in enumerate(row):
                if not v:
                    continue
                for sy in range(scale):
                    for sx in range(scale):
                        px(img, cx + gx * scale + sx, y + gy * scale + sy, col)
        cx += (w + 1) * scale
    if glow:
        # jemná záře kolem nápisu: dither do okolních pixelů
        base = img.copy()
        for yy in range(y - 2, y + 11 * scale + 2):
            for xx in range(x - 2, cx + 2):
                if not (0 <= xx < img.width and 0 <= yy < img.height):
                    continue
                if base.getpixel((xx, yy)) == c(col):
                    continue
                near = any(
                    0 <= xx + dx < img.width and 0 <= yy + dy < img.height
                    and base.getpixel((xx + dx, yy + dy)) == c(col)
                    for dx in (-2, -1, 0, 1, 2) for dy in (-2, -1, 0, 1, 2)
                )
                if near and dither(xx, yy, 0.5):
                    px(img, xx, yy, glow)
    return cx - x


def text_width(text, scale=1):
    return sum((len(ga.glyph_bitmap(ch)[0]) + 1) * scale for ch in text)


def sky(img, y0, y1, bands, seed=0, stars=40):
    w = img.width
    for y in range(y0, y1):
        t = min((y - y0) / max(y1 - y0, 1), 0.999) * (len(bands) - 1)
        i = int(t)
        f = t - i
        for x in range(w):
            px(img, x, y, bands[min(i + 1, len(bands) - 1)] if dither(x, y, f) else bands[i])
    rnd = random.Random(seed)
    for _ in range(stars):
        px(img, rnd.randrange(w), rnd.randrange(y0, y0 + (y1 - y0) // 2), rnd.choice(["G2", "G3", "N2"]))


def towers(img, y_top_range, base_y, color, windows, lit, seed, x0=0, x1=None, antenna_p=0.3):
    rnd = random.Random(seed)
    x1 = x1 if x1 is not None else img.width
    x = x0
    while x < x1:
        wd = rnd.randrange(10, 24)
        top = rnd.randrange(*y_top_range)
        rect(img, x, top, x + wd - 1, base_y, color)
        if rnd.random() < antenna_p:
            vline(img, x + wd // 2, top - 8, top, color)
            px(img, x + wd // 2, top - 9, "R3")
        for wy in range(top + 2, base_y - 1, 3):
            for wx in range(x + 2, x + wd - 2, 3):
                if rnd.random() < lit:
                    px(img, wx, wy, rnd.choice(windows))
        x += wd + rnd.randrange(0, 4)


# --- Slumy (430x300) --------------------------------------------------------
SLUM_W, SLUM_H = 430, 300
GROUND_Y = 236
BAR_POS = (292, 236 - 145)  # levý horní roh baru v herních pixelech

HOMELESS_SIT = [
    "...kkk...",
    "..kbbbk..",
    ".kbbsbbk.",
    ".kbbbbbk.",
    "..kbbbk..",
    ".kbbbbbbk",
    "kbbbbbbbk",
    "kbbsbbsbk",
    "kbbbbbbbk",
    ".kbbbbbk.",
    ".kkkkkkk.",
]

HOMELESS_STAND = [
    "..kkk..",
    ".kRRRk.",
    ".kSssk.",
    ".kSssk.",
    "..kkk..",
    ".kbbbk.",
    "kbbbbbk",
    "ksbbbsk",
    "kbbbbbk",
    ".kbbbk.",
    ".kbkbk.",
    ".kbkbk.",
    ".kk.kk.",
]

CART = [
    "k.........",
    ".kkkkkkkkk",
    ".kGkGkGkGk",
    ".kkkkkkkkk",
    "..kGkGkGk.",
    "..kkkkkkk.",
    "...k...k..",
    "..kGk.kGk.",
]


def shack(img, x, w, h, col, rnd):
    top = GROUND_Y - h
    rect(img, x, top, x + w - 1, GROUND_Y, col)
    # vlnitý plech: svislé tmavší pruhy
    for sx in range(x, x + w, 3):
        vline(img, sx, top, GROUND_Y, "K1" if col in ("G1", "#3a4a4a") else "K2")
    vline(img, x, top, GROUND_Y, "K0")
    vline(img, x + w - 1, top, GROUND_Y, "K0")
    # šikmá střecha s přesahem
    slope = rnd.randrange(2, 6)
    for i in range(w + 4):
        yy = top - slope + (slope * i) // (w + 4)
        px(img, x - 2 + i, yy, "K0")
        px(img, x - 2 + i, yy + 1, "K3")
        if x <= x - 2 + i < x + w:
            for fill in range(yy + 2, top + 1):
                px(img, x - 2 + i, fill, "K2")
    # okno
    if w > 18 and rnd.random() < 0.8:
        wx = x + rnd.randrange(3, w - 12)
        wy = top + rnd.randrange(4, max(5, h - 20))
        rect(img, wx, wy, wx + 8, wy + 6, "K0")
        lit = rnd.random() < 0.6
        rect(img, wx + 1, wy + 1, wx + 7, wy + 5, "Y0" if lit else "K1")
        if lit:
            for yy in range(wy + 1, wy + 6):
                for xx in range(wx + 1, wx + 8):
                    if dither(xx, yy, 0.3):
                        px(img, xx, yy, "Y1")
        vline(img, wx + 4, wy, wy + 6, "K0")
    # dveře nebo hadr místo dveří
    if rnd.random() < 0.7:
        dx = x + w // 2 - 3
        rect(img, dx, GROUND_Y - 14, dx + 6, GROUND_Y, "K0")
        rect(img, dx + 1, GROUND_Y - 13, dx + 5, GROUND_Y, rnd.choice(["K1", "R0", "B0"]))
    return top - slope


def fire_barrel(img, x, y):
    """Sud s ohněm, (x, y) je levý dolní roh sudu."""
    # záře na okolí
    cx, cy, r = x + 5, y - 16, 34
    base = img.copy()
    for yy in range(cy - r, cy + r):
        for xx in range(cx - r, cx + r):
            if not (0 <= xx < img.width and 0 <= yy < img.height):
                continue
            d = ((xx - cx) ** 2 + (yy - cy) ** 2) ** 0.5
            if d < r and dither(xx, yy, (1 - d / r) * 0.55):
                cur = base.getpixel((xx, yy))
                if cur[3] and sum(cur[:3]) < 260:
                    px(img, xx, yy, "R0" if d > r * 0.5 else "W1")
    rect(img, x, y - 13, x + 10, y, "K0")
    rect(img, x + 1, y - 12, x + 9, y, "G1")
    vline(img, x + 2, y - 12, y, "G2")
    hline(img, x + 1, x + 9, y - 9, "K3")
    hline(img, x + 1, x + 9, y - 3, "K3")
    flame = [
        "....y.....",
        "...yY..y..",
        "..yYYy.Y..",
        ".yYwYYyYy.",
        ".YwwwYYYy.",
        "yYwwwwYYYy",
        "YYwwwwwYYY",
    ]
    fimg = from_ascii(flame, {"y": "R3", "Y": "Y1", "w": "Y2"})
    img.alpha_composite(fimg, (x + 1, y - 20))


def gen_slums() -> None:
    img = new(SLUM_W, SLUM_H)
    sky(img, 0, GROUND_Y, ["K0", "K1", "K2", "K3", "#4a2d55"], seed=5, stars=50)
    # bohaté věže nahoře v dálce
    towers(img, (20, 90), 150, "#2a2140", ["Y2", "#5a4a7a", "N2"], 0.28, seed=11, antenna_p=0.4)
    rect(img, 160, 4, 190, 150, "#2a2140")  # hlavní věž
    vline(img, 175, 0, 4, "#2a2140")
    for wy in range(8, 148, 3):
        for wx in range(163, 189, 3):
            if random.Random(wx * 31 + wy).random() < 0.45:
                px(img, wx, wy, "Y2")
    # smog nad slumy
    for y in range(120, 170):
        for x in range(SLUM_W):
            if dither(x, y, (y - 120) / 50 * 0.5):
                px(img, x, y, "#4a2d55")

    rnd = random.Random(21)
    # druhá řada chatrčí (vzadu, tmavší)
    x = -6
    while x < SLUM_W:
        w = rnd.randrange(20, 40)
        h = rnd.randrange(50, 80)
        shack(img, x, w, h, rnd.choice(["K2", "#3a4a4a", "R0"]), rnd)
        x += w + rnd.randrange(-4, 3)
    # prádlo mezi chatrčemi
    for (x0, x1, yy) in [(20, 80, 175), (110, 170, 168), (200, 270, 172)]:
        for i in range(x1 - x0):
            sag = int(4 * (1 - ((i / (x1 - x0)) * 2 - 1) ** 2))
            px(img, x0 + i, yy + sag, "G2")
            if i % 9 == 3:
                col = rnd.choice(["R2", "B2", "P2", "O3"])
                rect(img, x0 + i, yy + sag + 1, x0 + i + 3, yy + sag + 5, col)
    # přední řada (nižší, světlejší), vynechat místo pro bar vpravo
    x = -4
    while x < 280:
        w = rnd.randrange(26, 46)
        h = rnd.randrange(30, 52)
        shack(img, x, w, h, rnd.choice(["G1", "W1", "#3a4a4a"]), rnd)
        x += w + rnd.randrange(2, 8)

    # zem: asfalt, louže s odlesky neonu
    rect(img, 0, GROUND_Y, SLUM_W - 1, SLUM_H - 1, "K1")
    hline(img, 0, SLUM_W - 1, GROUND_Y, "K0")
    for y in range(GROUND_Y + 1, SLUM_H):
        for x in range(SLUM_W):
            r = random.Random(x * 977 + y * 131).random()
            if r < 0.06:
                px(img, x, y, "K2")
    for (cx, cy, rw, rh, neon) in [(60, 270, 26, 5, "N2"), (210, 285, 34, 6, "N1"), (340, 262, 22, 4, "N1")]:
        d = ImageDraw.Draw(img)
        d.ellipse([cx - rw, cy - rh, cx + rw, cy + rh], fill=c("K2"))
        for y in range(cy - rh, cy + rh):
            for x in range(cx - rw, cx + rw):
                if img.getpixel((x, y)) == c("K2") and dither(x, y, 0.18):
                    px(img, x, y, neon)
    # odpadky, krabice
    for (bx, by) in [(30, GROUND_Y + 8), (250, GROUND_Y + 4), (120, GROUND_Y + 30)]:
        rect(img, bx, by, bx + 12, by + 8, "K0")
        rect(img, bx + 1, by + 1, bx + 11, by + 7, "W2")
        hline(img, bx + 1, bx + 11, by + 3, "W1")
    # sud s ohněm a bezdomovci kolem
    fire_barrel(img, 150, GROUND_Y + 24)
    sit = from_ascii(HOMELESS_SIT, {"k": "K0", "b": "W1", "s": "S2"})
    stand = from_ascii(HOMELESS_STAND, {"k": "K0", "b": "#3a4a4a", "s": "S2", "S": "S2", "R": "R1"})
    stand2 = from_ascii(HOMELESS_STAND, {"k": "K0", "b": "W0", "s": "S3", "S": "S3", "R": "B1"})
    img.alpha_composite(sit, (134, GROUND_Y + 13))
    img.alpha_composite(stand, (165, GROUND_Y + 10))
    img.alpha_composite(stand2, (143, GROUND_Y + 30))
    # ležící na kartonu
    rect(img, 40, GROUND_Y + 40, 76, GROUND_Y + 44, "W2")
    rect(img, 44, GROUND_Y + 36, 72, GROUND_Y + 41, "K0")
    rect(img, 45, GROUND_Y + 37, 71, GROUND_Y + 40, "B0")
    rect(img, 72, GROUND_Y + 36, 76, GROUND_Y + 40, "K0")
    rect(img, 73, GROUND_Y + 37, 75, GROUND_Y + 39, "S2")
    img.alpha_composite(from_ascii(CART, {"k": "K0", "G": "G3"}), (88, GROUND_Y + 32))
    # lampa
    vline(img, 268, 150, GROUND_Y, "K0")
    hline(img, 262, 268, 150, "K0")
    rect(img, 260, 151, 264, 153, "Y2")
    for y in range(154, 200):
        for x in range(250, 276):
            spread = (y - 154) // 3
            if 262 - spread <= x <= 262 + spread and dither(x, y, 0.15):
                px(img, x, y, "Y0")
    save(img, "world/slums.png")


def make_bar(neon: str, glow: str, bright: bool) -> Image.Image:
    w, h = 130, 145
    img = new(w, h)
    top = 26
    # cihlová zeď
    rect(img, 0, top, w - 1, h - 1, "R0")
    for y in range(top, h):
        if (y - top) % 5 == 0:
            hline(img, 0, w - 1, y, "K2")
        else:
            off = 0 if ((y - top) // 5) % 2 == 0 else 5
            for x in range(off, w, 10):
                px(img, x, y, "K2")
    for x in range(0, w):
        for y in range(top, h):
            if random.Random(x * 13 + y * 7).random() < 0.05:
                px(img, x, y, "R1")
    # atika
    rect(img, 0, top - 4, w - 1, top, "K3")
    hline(img, 0, w - 1, top - 4, "G1")
    # neonová cedule na střeše
    sign_w = text_width("BAR", 3) + 10
    sx = (w - sign_w) // 2
    rect(img, sx, 0, sx + sign_w, top - 5, "K0")
    vline(img, sx + 6, top - 5, top - 4, "K0")
    vline(img, sx + sign_w - 6, top - 5, top - 4, "K0")
    draw_text(img, sx + 6, -4, "BAR", neon, 3, glow=glow)
    # cedulka s názvem
    name = "U ZLATÉ KRYSY"
    tw = text_width(name)
    rect(img, (w - tw) // 2 - 4, top + 4, (w + tw) // 2 + 2, top + 16, "K0")
    rect(img, (w - tw) // 2 - 3, top + 5, (w + tw) // 2 + 1, top + 15, "Y0")
    draw_text(img, (w - tw) // 2, top + 4, name, "Y2" if bright else "Y1")
    # okna s hosty
    for wx in (10, w - 38):
        rect(img, wx, top + 26, wx + 28, top + 52, "K0")
        rect(img, wx + 1, top + 27, wx + 27, top + 51, "Y0")
        for yy in range(top + 27, top + 52):
            for xx in range(wx + 1, wx + 28):
                if dither(xx, yy, 0.4 if bright else 0.25):
                    px(img, xx, yy, "Y1")
        # siluety hostů
        for hx in (wx + 5, wx + 16):
            d = ImageDraw.Draw(img)
            d.ellipse([hx, top + 34, hx + 6, top + 40], fill=c("K1"))
            rect(img, hx - 1, top + 41, hx + 7, top + 51, "K1")
        vline(img, wx + 14, top + 26, top + 52, "K0")
    # dveře
    dx = w // 2 - 11
    rect(img, dx, h - 44, dx + 22, h - 4, "K0")
    rect(img, dx + 1, h - 43, dx + 21, h - 4, "W1")
    vline(img, dx + 11, h - 43, h - 4, "W0")
    d = ImageDraw.Draw(img)
    d.ellipse([dx + 7, h - 38, dx + 15, h - 30], fill=c("K0"))
    d.ellipse([dx + 8, h - 37, dx + 14, h - 31], fill=c("Y1" if bright else "Y0"))
    px(img, dx + 17, h - 22, "Y1")
    # lampa nad dveřmi
    rect(img, w // 2 - 3, h - 50, w // 2 + 3, h - 47, "K0")
    hline(img, w // 2 - 2, w // 2 + 2, h - 47, "Y2")
    # schody
    rect(img, dx - 4, h - 4, dx + 26, h - 1, "G1")
    hline(img, dx - 4, dx + 26, h - 4, "G2")
    # krysí graffiti
    rat = [
        "..kk.......",
        ".kGGk..kk..",
        "kGeGGkkGGk.",
        ".kGGGGGGGGk",
        "..kGGGGGGk.",
        "...kk..kk..",
        "............",
    ]
    img.alpha_composite(from_ascii(rat, {"k": "K1", "G": "G3", "e": "R3"}), (8, h - 18))
    img = outline(pad(img), "K0")
    if bright:
        img = ImageEnhance.Brightness(img).enhance(1.15)
        img = outline(pad(img), "Y2")
    else:
        img = pad(img)
    return img


def gen_bar_outside() -> None:
    save(make_bar("N1", "#7a2050", False), "world/bar.png")
    save(make_bar("PK", "N1", True), "world/bar_hover.png")


# --- Úřad / soud (170x110) --------------------------------------------------

def make_urad() -> Image.Image:
    w, h = 170, 110
    img = new(w, h)
    sky(img, 0, h, ["K1", "K2", "K3", "#4a2d55"], seed=8, stars=20)
    towers(img, (10, 50), h, "#2a2140", ["Y2", "#5a4a7a"], 0.25, seed=9)
    bx0, bx1 = 22, 148
    # schody
    for i, y in enumerate(range(92, 104, 3)):
        rect(img, bx0 - 6 - i * 3, y, bx1 + 6 + i * 3, y + 2, "G2")
        hline(img, bx0 - 6 - i * 3, bx1 + 6 + i * 3, y, "G3")
    rect(img, 0, 104, w - 1, h - 1, "K1")
    # tělo budovy
    rect(img, bx0, 48, bx1, 92, "G2")
    # portikus: tmavý prostor mezi sloupy
    rect(img, bx0 + 4, 54, bx1 - 4, 92, "K2")
    # dveře
    rect(img, 76, 64, 94, 92, "K0")
    rect(img, 77, 65, 93, 92, "W0")
    vline(img, 85, 65, 92, "K1")
    # sloupy
    for i in range(7):
        cx = bx0 + 6 + i * 20
        if 72 <= cx <= 96:
            continue
        rect(img, cx, 54, cx + 7, 92, "G4")
        vline(img, cx + 6, 54, 92, "G3")
        vline(img, cx + 7, 54, 92, "G2")
        rect(img, cx - 1, 52, cx + 8, 54, "G3")
        rect(img, cx - 1, 90, cx + 8, 92, "G3")
    # kladí
    rect(img, bx0 - 4, 44, bx1 + 4, 50, "G4")
    hline(img, bx0 - 4, bx1 + 4, 44, "P4")
    hline(img, bx0 - 4, bx1 + 4, 50, "G2")
    # štít s nápisem
    peak = 16
    for y in range(peak, 44):
        half = int((y - peak) / (44 - peak) * ((bx1 - bx0) / 2 + 6))
        mid = (bx0 + bx1) // 2
        hline(img, mid - half, mid + half, y, "G3")
        px(img, mid - half, y, "K0")
        px(img, mid + half, y, "K0")
    tw = text_width("ÚŘAD")
    draw_text(img, (bx0 + bx1) // 2 - tw // 2, 27, "ÚŘAD", "K1")
    # vlajka
    vline(img, 85, 2, peak, "K0")
    rect(img, 86, 2, 98, 8, "R2")
    hline(img, 86, 98, 5, "R1")
    # fronta drobných lidiček na schodech
    rnd = random.Random(4)
    for i in range(9):
        fx = 28 + i * 6 + (2 if i > 4 else 0)
        if 72 <= fx <= 98:
            fx += 30
        fy = 95 + (i % 3) * 3
        col = rnd.choice(["G1", "B1", "W1", "R1"])
        rect(img, fx, fy - 4, fx + 2, fy + 2, col)
        px(img, fx + 1, fy - 5, "S2")
        px(img, fx + 1, fy - 6, "S2")
    # rám
    ImageDraw.Draw(img).rectangle([0, 0, w - 1, h - 1], outline=c("K0"))
    return img


def gen_urad() -> None:
    img = make_urad()
    save(img, "world/urad.png")
    hover = ImageEnhance.Brightness(img).enhance(1.2)
    d = ImageDraw.Draw(hover)
    d.rectangle([0, 0, hover.width - 1, hover.height - 1], outline=c("Y1"))
    d.rectangle([1, 1, hover.width - 2, hover.height - 2], outline=c("Y2"))
    save(hover, "world/urad_hover.png")
    grey = ImageOps.grayscale(img.convert("RGB")).convert("RGBA")
    grey = ImageEnhance.Brightness(grey).enhance(0.55)
    # cedule ZAVŘENO přes dveře
    label = "ZAVŘENO"
    tw = text_width(label)
    x0 = (grey.width - tw) // 2 - 4
    rect(grey, x0, 70, x0 + tw + 7, 82, "K0")
    rect(grey, x0 + 1, 71, x0 + tw + 6, 81, "R1")
    draw_text(grey, x0 + 4, 70, label, "P3")
    save(grey, "world/urad_disabled.png")


# --- Bar zevnitř (640x360) --------------------------------------------------
COUNTER_Y = 228


def bottles(img, x0, x1, shelf_y, seed):
    rnd = random.Random(seed)
    x = x0
    while x < x1 - 5:
        bh = rnd.randrange(8, 14)
        col = rnd.choice(["O2", "R1", "B1", "Y0", "W2", "O3", "PU"])
        rect(img, x, shelf_y - bh, x + 3, shelf_y - 1, "K0")
        rect(img, x + 1, shelf_y - bh + 1, x + 2, shelf_y - 1, col)
        vline(img, x + 1, shelf_y - bh + 2, shelf_y - 3, "G3")
        rect(img, x + 1, shelf_y - bh - 3, x + 2, shelf_y - bh, "K0")
        x += rnd.randrange(5, 9)
    rect(img, x0 - 2, shelf_y, x1 + 2, shelf_y + 2, "W2")
    hline(img, x0 - 2, x1 + 2, shelf_y, "W3")
    hline(img, x0 - 2, x1 + 2, shelf_y + 3, "K0")


def wood_wall(img, y0, y1, seed=0):
    rnd = random.Random(seed)
    rect(img, 0, y0, img.width - 1, y1, "W0")
    for x in range(0, img.width, 14):
        vline(img, x, y0, y1, "#2a1a10")
        for y in range(y0, y1):
            if rnd.random() < 0.08:
                px(img, x + rnd.randrange(2, 12), y, "W1")


def lamp(img, cx, y0, length, radius):
    vline(img, cx, 0, y0, "K0")
    rect(img, cx - 5, y0, cx + 5, y0 + 4, "K0")
    rect(img, cx - 4, y0 + 1, cx + 4, y0 + 3, "O1")
    hline(img, cx - 3, cx + 3, y0 + 5, "Y2")
    base = img.copy()
    for y in range(y0 + 6, y0 + 6 + length):
        spread = int((y - y0) * radius / length) + 3
        for x in range(cx - spread, cx + spread + 1):
            if 0 <= x < img.width and dither(x, y, 0.22 * (1 - (y - y0) / length) + 0.05):
                cur = base.getpixel((x, y))
                if cur[3]:
                    px(img, x, y, "Y0")


def barman_sprite() -> Image.Image:
    w, h = 70, 90
    img = new(w, h)
    d = ImageDraw.Draw(img)
    cx = w // 2
    # paže
    rect(img, cx - 28, 34, cx - 19, 80, "S1")
    vline(img, cx - 20, 36, 80, "S2")
    rect(img, cx + 19, 34, cx + 28, 80, "S1")
    vline(img, cx + 27, 36, 80, "S2")
    # trup: tílko a zástěra
    d.rounded_rectangle([cx - 21, 26, cx + 21, 89], radius=6, fill=c("S1"))
    rect(img, cx - 14, 28, cx + 14, 89, "G4")
    rect(img, cx - 13, 48, cx + 13, 89, "P2")
    hline(img, cx - 13, cx + 13, 48, "P1")
    for x0 in (cx - 13, cx + 11):
        vline(img, x0, 30, 48, "P1")
        vline(img, x0 + 1, 30, 48, "P1")
    rect(img, cx - 6, 60, cx + 6, 68, "P1")
    # krk a hlava
    rect(img, cx - 6, 20, cx + 6, 28, "S2")
    d.ellipse([cx - 11, 0, cx + 11, 24], fill=c("S1"))
    d.ellipse([cx + 3, 2, cx + 11, 22], fill=c("S2"))
    # vousy
    d.ellipse([cx - 11, 12, cx + 11, 34], fill=c("W0"))
    rect(img, cx - 5, 17, cx + 5, 18, "S1")
    hline(img, cx - 4, cx + 4, 21, "R1")
    # oči: jedno oko, druhé páska
    hline(img, cx - 7, cx - 2, 8, "K0")
    px(img, cx - 5, 10, "K0")
    rect(img, cx + 2, 8, cx + 7, 12, "K0")
    d.line([cx - 10, 4, cx + 9, 12], fill=c("K0"))
    # ruce na pultu
    rect(img, cx - 30, 80, cx - 18, 86, "S1")
    rect(img, cx + 18, 80, cx + 30, 86, "S1")
    return outline(pad(img), "K0")


def bar_base(curtain_open: bool) -> Image.Image:
    w, h = 640, 360
    img = new(w, h)
    wood_wall(img, 0, COUNTER_Y, seed=2)
    # lišta a cihly dole za pultem
    rect(img, 0, 150, w - 1, COUNTER_Y, "R0")
    for y in range(150, COUNTER_Y):
        if (y - 150) % 6 == 0:
            hline(img, 0, w - 1, y, "K2")
        else:
            off = 0 if ((y - 150) // 6) % 2 == 0 else 6
            for x in range(off, w, 12):
                px(img, x, y, "K2")
    hline(img, 0, w - 1, 149, "W3")
    hline(img, 0, w - 1, 150, "K0")
    # police s lahvemi
    bottles(img, 150, 270, 70, 1)
    bottles(img, 350, 470, 70, 2)
    bottles(img, 150, 270, 112, 3)
    bottles(img, 350, 470, 112, 4)
    # zrcadlo uprostřed
    rect(img, 280, 40, 340, 120, "K0")
    rect(img, 281, 41, 339, 119, "Y0")
    rect(img, 283, 43, 337, 117, "K2")
    for i in range(0, 40, 6):
        for t in range(30):
            px(img, 290 + i + t // 2, 50 + t, "K3")
    # plakát HLEDÁ SE s krysou
    rect(img, 40, 40, 100, 110, "K0")
    rect(img, 41, 41, 99, 109, "P2")
    draw_text(img, 46, 41, "HLEDÁ SE", "R1")
    rat = [
        "...kk.....kk...",
        "..kGGk...kGGk..",
        "..kGPGkkkGPGk..",
        "...kGGGGGGGk...",
        "..kGGeGGGeGGk..",
        "..kGGGGGGGGGk..",
        "...kGGGrGGGk...",
        "....kGGGGGk....",
        ".....kkkkk.....",
    ]
    img.alpha_composite(from_ascii(rat, {"k": "K0", "G": "G2", "P": "PK", "e": "K0", "r": "PK"}), (52, 60))
    draw_text(img, 52, 78, "ŽIVÁ", "K1")
    draw_text(img, 46, 92, "50 GROŠŮ", "K1")
    # šipky v terči
    d = ImageDraw.Draw(img)
    d.ellipse([500, 50, 530, 80], fill=c("K0"))
    d.ellipse([502, 52, 528, 78], fill=c("R1"))
    d.ellipse([507, 57, 523, 73], fill=c("P3"))
    d.ellipse([512, 62, 518, 68], fill=c("R2"))
    # závěs vpravo
    cx0, cx1, ctop, cbot = 548, 620, 50, COUNTER_Y + 60
    rect(img, cx0 - 4, ctop - 6, cx1 + 4, cbot, "K0")
    rect(img, cx0, ctop, cx1, cbot, "K1")
    if curtain_open:
        # průhled dozadu: šero a žárovka
        for y in range(ctop, cbot):
            for x in range(cx0, cx1):
                if dither(x, y, 0.15):
                    px(img, x, y, "K2")
        rect(img, cx0 + 30, ctop + 10, cx0 + 33, ctop + 13, "Y1")
        drape = [(cx0, cx0 + 14), (cx1 - 14, cx1)]
    else:
        drape = [(cx0, cx1)]
    for a, b in drape:
        for x in range(a, b + 1):
            fold = (x - a) % 8
            col = "R2" if fold in (2, 3) else ("R0" if fold in (6, 7) else "R1")
            vline(img, x, ctop, cbot, col)
    rect(img, cx0 - 6, ctop - 8, cx1 + 6, ctop - 5, "Y0")
    hline(img, cx0 - 6, cx1 + 6, ctop - 8, "Y1")
    # lampy
    lamp(img, 200, 10, 120, 40)
    lamp(img, 430, 10, 120, 40)
    return img


def counter(img):
    w = img.width
    rect(img, 0, COUNTER_Y, w - 1, COUNTER_Y + 8, "W2")
    hline(img, 0, w - 1, COUNTER_Y, "W3")
    hline(img, 0, w - 1, COUNTER_Y + 1, "W3")
    hline(img, 0, w - 1, COUNTER_Y + 8, "K0")
    rect(img, 0, COUNTER_Y + 9, w - 1, 300, "W1")
    for x in range(0, w, 20):
        vline(img, x, COUNTER_Y + 9, 300, "W0")
    hline(img, 0, w - 1, 300, "K0")
    # podlaha
    for y in range(301, img.height):
        for x in range(w):
            px(img, x, y, "K2" if ((x // 16) + (y // 8)) % 2 else "K1")
    # pivní kohout a sklenice
    rect(img, 120, COUNTER_Y - 18, 124, COUNTER_Y, "G3")
    rect(img, 116, COUNTER_Y - 22, 128, COUNTER_Y - 18, "G4")
    rect(img, 121, COUNTER_Y - 28, 123, COUNTER_Y - 22, "K0")
    for gx in (380, 395, 470):
        rect(img, gx, COUNTER_Y - 10, gx + 7, COUNTER_Y - 1, "K0")
        rect(img, gx + 1, COUNTER_Y - 9, gx + 6, COUNTER_Y - 1, "Y1")
        hline(img, gx + 1, gx + 6, COUNTER_Y - 9, "P4")
    # stoličky
    for sx in (90, 230, 420, 520):
        rect(img, sx, 310, sx + 24, 315, "K0")
        rect(img, sx + 1, 311, sx + 23, 314, "R1")
        vline(img, sx + 12, 316, 359, "K0")
        vline(img, sx + 11, 316, 359, "G1")


def gen_bar_inside() -> None:
    for name, opened in (("bar_inside", False), ("bar_inside_open", True)):
        img = bar_base(opened)
        if not opened:
            img.alpha_composite(barman_sprite(), (282, COUNTER_Y - 88))
        counter(img)
        save(img, f"world/{name}.png")


def gen_back_room() -> None:
    w, h = 640, 360
    img = new(w, h)
    # betonová zeď
    for y in range(h):
        for x in range(w):
            px(img, x, y, "K3" if dither(x, y, 0.35 - y / h * 0.3) else "K2")
    rect(img, 0, 280, w - 1, h - 1, "K1")
    hline(img, 0, w - 1, 280, "K0")
    # bedny vlevo
    for (bx, by, bw, bh) in [(20, 220, 70, 60), (90, 235, 60, 45), (35, 170, 55, 50)]:
        rect(img, bx, by, bx + bw, by + bh, "K0")
        rect(img, bx + 1, by + 1, bx + bw - 1, by + bh - 1, "W1")
        for yy in range(by + 6, by + bh, 8):
            hline(img, bx + 1, bx + bw - 1, yy, "W0")
        ImageDraw.Draw(img).line([bx + 1, by + 1, bx + bw - 1, by + bh - 1], fill=c("W0"))
    # police se sklenicemi (tlapy ve formaldehydu)
    for sy in (90, 150):
        rect(img, 470, sy, 620, sy + 3, "W2")
        hline(img, 470, 620, sy, "W3")
        for jx in range(478, 612, 22):
            rect(img, jx, sy - 20, jx + 14, sy - 1, "K0")
            rect(img, jx + 1, sy - 19, jx + 13, sy - 1, "O3")
            for yy in range(sy - 19, sy - 1):
                for xx in range(jx + 1, jx + 14):
                    if dither(xx, yy, 0.3):
                        px(img, xx, yy, "O4")
            rect(img, jx, sy - 23, jx + 14, sy - 20, "G2")
            # růžová tlapka uvnitř
            rect(img, jx + 5, sy - 12, jx + 9, sy - 5, "PK")
            for fx in range(jx + 4, jx + 11, 2):
                vline(img, fx, sy - 15, sy - 12, "PK")
    # žárovka
    lamp(img, 320, 0, 200, 90)
    # stůl dole uprostřed
    rect(img, 200, 300, 440, 308, "W2")
    hline(img, 200, 440, 300, "W3")
    rect(img, 210, 309, 216, 359, "W0")
    rect(img, 424, 309, 430, 359, "W0")
    save(img, "world/back_room.png")


# --- Portréty postav --------------------------------------------------------
CHARLATAN_HALF = [
    "....................",
    "........kkkkkkkkkkkk",
    "........khhhhhhhhhhh",
    "........khhhhhhhhhhh",
    "........khhhhhhhhhhh",
    "........khhhhhhhhhhh",
    "........kHHHHHHHHHHH",
    "....kkkkkhhhhhhhhhhh",
    "...khhhhhhhhhhhhhhhh",
    "....kkkkksssssssssss",
    ".......kssssssssssss",
    ".......ksskkkkssssss",
    ".......ksssekkssssss",
    ".......kSssssssssssS",
    ".......kSsssssssssSS",
    "....mm.kSsssssmmmmmm",
    ".....mmmmSssmmmmmmmm",
    "........kSsssrrrrryr",
    "........kSSsssssssss",
    ".........kSSssssssss",
    "..........kkSSSsssss",
    "............kkkSSSSS",
    "..........kkkkkwSSSS",
    "......kkkkcccckwwwtt",
    "....kkccccccccckwwtt",
    "...kcccccccccccckwwt",
    "..kcccccccccccccckww",
    "..kccCcccccccccccckw",
    ".kccCccccccccccccckw",
    ".kccCcccccccyccccckw",
    ".kccCccccccccyyccckw",
    "kcccCccccccccccccckw",
    "kccccccccccccccccckw",
    "kccccccccccccccccckw",
    "kccccccccccccccccckw",
    "kccccccccccccccccckw",
    "kccccccccccccccccckw",
    "kccccccccccccccccckw",
    "kccccccccccccccccckw",
    "kccccccccccccccccckw",
]

BARMAN_HALF = [
    "....................",
    "....................",
    "...........kkkkkkkkk",
    ".........kksssssssss",
    "........ksssssssssss",
    ".......kssssssssssss",
    ".......kssssssssssss",
    ".......kSsssssssssss",
    ".......kSskkkkksssss",
    ".......kSssekkssssss",
    "......kkSsssssssssss",
    "......ksSssssssssSSs",
    "......kkSsssssssSSSS",
    ".......kbbbbsssbbbbb",
    ".......kbbbbbbbbrrrr",
    ".......kbbbbbbbbbbbb",
    ".......kbbbbbbbbbbbb",
    "........kbbbbbbbbbbb",
    ".........kbbbbbbbbbb",
    "..........kkbbbbbbbb",
    "............kkkkbbbb",
    "..............kSSSSS",
    ".......kkkkkkkkSSSSS",
    ".....kksssssstkSSSSS",
    "....kssssssstttkSSSS",
    "...ksssssssttttttttt",
    "..kSssssssttaaaaaaaa",
    "..kSsssssstaaaaaaaaa",
    ".kSssssssstaaaaaaaaa",
    ".kSssssssstaaaaaaaaa",
    "kSsssssssstaaaaaaaaa",
    "kSsssssssstaaaaaaaaa",
    "kSsssssssstaaaaaaaaa",
    "kSsssssssstaaaaaaaaa",
    "kSsssssssstaaaaaaaaa",
    "kSsssssssstaaaaaaaaa",
    "kSsssssssstaaaaaaaaa",
    "kSsssssssstaaaaaaaaa",
    "kSsssssssstaaaaaaaaa",
    "kSsssssssstaaaaaaaaa",
]


def alley_bg(img):
    for y in range(40):
        for x in range(40):
            px(img, x, y, "PU" if dither(x, y, 0.3 + y / 80) else "K2")
    for x0 in (2, 30):
        rect(img, x0, 6, x0 + 6, 14, "K0")
        rect(img, x0 + 1, 7, x0 + 5, 13, "N1" if x0 < 10 else "N2")


def bar_bg(img):
    for y in range(40):
        for x in range(40):
            px(img, x, y, "W0" if x % 7 else "#2a1a10")
    rnd = random.Random(2)
    for x in range(1, 40, 4):
        col = rnd.choice(["O2", "R1", "B1", "Y0"])
        rect(img, x, 4, x + 1, 10, col)
    hline(img, 0, 39, 11, "W2")


def gen_character_portraits() -> None:
    ch_leg = {
        "k": "K0", "h": "K2", "H": "R1", "s": "S1", "S": "S2", "e": "K0", "m": "W0",
        "y": "Y1", "r": "R1", "w": "P3", "t": "R2", "c": "PU", "C": "PL",
    }

    def ch_fix(rows):
        # šilhavé oko: na pravé straně jiné místo, zlatý zub jen jeden
        rows = [list(r) for r in rows]
        rows[17][21] = "r"
        return ["".join(r) for r in rows]

    save(ga.portrait(CHARLATAN_HALF, ch_leg, alley_bg, ch_fix), "portraits/charlatan.png")

    bm_leg = {
        "k": "K0", "s": "S1", "S": "S2", "e": "K0", "b": "W0", "r": "R1",
        "t": "G4", "a": "P2",
    }

    def bm_fix(rows):
        rows = [list(r) for r in rows]
        # páska přes pravé oko a řemínek přes hlavu
        for y in range(8, 11):
            for x in range(25, 31):
                rows[y][x] = "k"
        for i, y in enumerate(range(3, 8)):
            rows[y][26 - i * 3] = "k"
            rows[y][27 - i * 3] = "k"
        return ["".join(r) for r in rows]

    save(ga.portrait(BARMAN_HALF, bm_leg, bar_bg, bm_fix), "portraits/barman.png")


def main() -> None:
    gen_slums()
    gen_bar_outside()
    gen_urad()
    gen_bar_inside()
    gen_back_room()
    gen_character_portraits()


if __name__ == "__main__":
    for _hex in ["#4a2d55", "#2a2140", "#5a4a7a"]:
        ga.PAL[_hex] = _hex
    main()
