#!/usr/bin/env python3
"""Generátor pixel-art grafiky pro Card Bureaucracy.

Všechno se kreslí v nativním rozlišení (1 pixel = 1 herní pixel) a ukládá
zvětšené 2x nejbližším sousedem, takže v Godotu (1280x720) sedí mřížka
640x360. Font se ukládá v 1x a v Godotu se škáluje celočíselně.

Spuštění: python3 tools/gen_assets.py
"""
from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets"
SCALE = 2

# --- Paleta -----------------------------------------------------------------
PAL = {
    "K0": "#0e0b14", "K1": "#1c1726", "K2": "#2b2438", "K3": "#3d3550",
    "G1": "#4a4a5e", "G2": "#6b6b80", "G3": "#9a9aab", "G4": "#c8c8d4",
    "P0": "#5e4a32", "P1": "#a8905f", "P2": "#d6c393", "P3": "#eee2bb", "P4": "#fff6da",
    "W0": "#3a2418", "W1": "#5c3a24", "W2": "#7e522f", "W3": "#a06d3d",
    "O0": "#16231f", "O1": "#22362e", "O2": "#33503f", "O3": "#4f7458", "O4": "#8fb38a",
    "R0": "#4a0f18", "R1": "#8a1e28", "R2": "#c43a3a", "R3": "#ee6b55",
    "B0": "#142040", "B1": "#22386e", "B2": "#3c5fb0", "B3": "#6f95e0",
    "N1": "#ff4f9a", "N2": "#44e5ff", "N3": "#b45cff",
    "Y0": "#9a6a1e", "Y1": "#f2c14e", "Y2": "#fff08a",
    "H0": "#1d4a2a", "H1": "#2f8a44", "H2": "#5fd35f", "H3": "#b4f08a",
    "S1": "#f0b88a", "S2": "#c98058", "S3": "#7a4a32",
    "PK": "#e88ca0", "PD": "#b45a72", "PU": "#4a2a6a", "PL": "#7a4aa0",
}


def c(name: str) -> tuple[int, int, int, int]:
    h = PAL[name].lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


CLEAR = (0, 0, 0, 0)


def new(w: int, h: int, fill=CLEAR) -> Image.Image:
    return Image.new("RGBA", (w, h), fill)


def save(img: Image.Image, name: str, scale: int = SCALE) -> None:
    path = OUT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    if scale != 1:
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    img.save(path)


def rect(img, x0, y0, x1, y1, col):
    """Vyplněný obdélník, souřadnice včetně x1, y1."""
    ImageDraw.Draw(img).rectangle([x0, y0, x1, y1], fill=c(col) if isinstance(col, str) else col)


def px(img, x, y, col):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c(col) if isinstance(col, str) else col)


def hline(img, x0, x1, y, col):
    rect(img, x0, y, x1, y, col)


def vline(img, x, y0, y1, col):
    rect(img, x, y0, x, y1, col)


BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def dither(x: int, y: int, t: float) -> bool:
    """True, když má pixel vzít druhou barvu při podílu t (0..1)."""
    return t * 16 > BAYER4[y % 4][x % 4] + 0.5


def from_ascii(rows: list[str], legend: dict[str, str], width: int | None = None) -> Image.Image:
    w = width or max(len(r) for r in rows)
    img = new(w, len(rows))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row.ljust(w, ".")):
            if ch in legend:
                px(img, x, y, legend[ch])
    return img


def mirror(half: list[str]) -> list[str]:
    return [r + r[::-1] for r in half]


# --- Font -------------------------------------------------------------------
# Řádky 0-1 akcenty velkých písmen, 2-8 výška verzálek, 9-10 dotahy.
# Glyf se zapisuje od řádku 2 (7 řádků + volitelně 2 dotahy).
GLYPHS: dict[str, list[str]] = {
    "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
    "C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
    "D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
    "G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
    "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "I": ["###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
    "J": ["...#", "...#", "...#", "...#", "#..#", "#..#", ".##."],
    "K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
    "L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
    "M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
    "N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
    "Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
    "W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
    "X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
    "Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
    "Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
    "a": ["....", "....", ".##.", "...#", ".###", "#..#", ".###"],
    "b": ["#...", "#...", "###.", "#..#", "#..#", "#..#", "###."],
    "c": ["...", "...", ".##", "#..", "#..", "#..", ".##"],
    "d": ["...#", "...#", ".###", "#..#", "#..#", "#..#", ".###"],
    "e": ["....", "....", ".##.", "#..#", "####", "#...", ".###"],
    "f": [".##", "#..", "###", "#..", "#..", "#..", "#.."],
    "g": ["....", "....", ".###", "#..#", "#..#", "#..#", ".###", "...#", ".##."],
    "h": ["#...", "#...", "###.", "#..#", "#..#", "#..#", "#..#"],
    "i": ["#", ".", "#", "#", "#", "#", "#"],
    "ı": [".", ".", "#", "#", "#", "#", "#"],
    "j": [".#", "..", ".#", ".#", ".#", ".#", ".#", ".#", "#."],
    "k": ["#...", "#...", "#..#", "#.#.", "##..", "#.#.", "#..#"],
    "l": ["#.", "#.", "#.", "#.", "#.", "#.", ".#"],
    "m": [".....", ".....", "####.", "#.#.#", "#.#.#", "#.#.#", "#.#.#"],
    "n": ["....", "....", "###.", "#..#", "#..#", "#..#", "#..#"],
    "o": ["....", "....", ".##.", "#..#", "#..#", "#..#", ".##."],
    "p": ["....", "....", "###.", "#..#", "#..#", "#..#", "###.", "#...", "#..."],
    "q": ["....", "....", ".###", "#..#", "#..#", "#..#", ".###", "...#", "...#"],
    "r": ["...", "...", "#.#", "##.", "#..", "#..", "#.."],
    "s": ["....", "....", ".###", "#...", ".##.", "...#", "###."],
    "t": [".#.", ".#.", "###", ".#.", ".#.", ".#.", "..#"],
    "u": ["....", "....", "#..#", "#..#", "#..#", "#..#", ".###"],
    "v": [".....", ".....", "#...#", "#...#", ".#.#.", ".#.#.", "..#.."],
    "w": [".....", ".....", "#...#", "#...#", "#.#.#", "#.#.#", ".#.#."],
    "x": ["....", "....", "#..#", "#..#", ".##.", "#..#", "#..#"],
    "y": ["....", "....", "#..#", "#..#", "#..#", "#..#", ".###", "...#", ".##."],
    "z": ["....", "....", "####", "...#", ".##.", "#...", "####"],
    "0": [".##.", "#..#", "#.##", "##.#", "#..#", "#..#", ".##."],
    "1": [".#.", "##.", ".#.", ".#.", ".#.", ".#.", "###"],
    "2": [".##.", "#..#", "...#", "..#.", ".#..", "#...", "####"],
    "3": ["###.", "...#", "...#", ".##.", "...#", "...#", "###."],
    "4": ["#..#", "#..#", "#..#", "####", "...#", "...#", "...#"],
    "5": ["####", "#...", "#...", "###.", "...#", "...#", "###."],
    "6": [".##.", "#...", "#...", "###.", "#..#", "#..#", ".##."],
    "7": ["####", "...#", "...#", "..#.", ".#..", ".#..", ".#.."],
    "8": [".##.", "#..#", "#..#", ".##.", "#..#", "#..#", ".##."],
    "9": [".##.", "#..#", "#..#", ".###", "...#", "...#", ".##."],
    ".": [".", ".", ".", ".", ".", ".", "#"],
    ",": ["..", "..", "..", "..", "..", "..", ".#", "#."],
    ":": [".", ".", "#", ".", ".", ".", "#"],
    ";": ["..", "..", ".#", "..", "..", "..", ".#", "#."],
    "!": ["#", "#", "#", "#", "#", ".", "#"],
    "?": [".##.", "#..#", "...#", "..#.", ".#..", "....", ".#.."],
    "-": ["...", "...", "...", "###", "...", "...", "..."],
    "–": ["....", "....", "....", "####", "....", "....", "...."],
    "+": ["...", "...", ".#.", "###", ".#.", "...", "..."],
    "=": ["...", "...", "###", "...", "###", "...", "..."],
    "/": ["..#", "..#", ".#.", ".#.", ".#.", "#..", "#.."],
    "(": [".#", "#.", "#.", "#.", "#.", "#.", ".#"],
    ")": ["#.", ".#", ".#", ".#", ".#", ".#", "#."],
    "%": ["##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##"],
    '"': ["#.#", "#.#", "...", "...", "...", "...", "..."],
    "'": ["#", "#", ".", ".", ".", ".", "."],
    "·": [".", ".", ".", "#", ".", ".", "."],
    "×": ["...", "...", "#.#", ".#.", "#.#", "...", "..."],
    "#": [".#.#.", "#####", ".#.#.", ".#.#.", "#####", ".#.#.", "....."],
    "_": ["....", "....", "....", "....", "....", "....", "....", "####"],
    "<": ["...", "..#", ".#.", "#..", ".#.", "..#", "..."],
    ">": ["...", "#..", ".#.", "..#", ".#.", "#..", "..."],
    "*": ["...", "#.#", ".#.", "#.#", "...", "...", "..."],
    "„": ["...", "...", "...", "...", "...", "...", "#.#", "#.#"],
    "“": ["#.#", "#.#", "...", "...", "...", "...", "..."],
    "›": ["..", "..", "#.", ".#", "#.", "..", ".."],
    "…": [".....", ".....", ".....", ".....", ".....", ".....", "#.#.#"],
    " ": ["...", "...", "...", "...", "...", "...", "..."],
}

# Znak s diakritikou: (základ, akcent). Velká písmena mají akcent nad verzálkou.
ACCENTED = {
    "á": ("a", "acute"), "č": ("c", "caron"), "é": ("e", "acute"), "ě": ("e", "caron"),
    "í": ("ı", "acute"), "ň": ("n", "caron"), "ó": ("o", "acute"), "ř": ("r", "caron"),
    "š": ("s", "caron"), "ú": ("u", "acute"), "ů": ("u", "ring"), "ý": ("y", "acute"),
    "ž": ("z", "caron"), "ď": ("d", "apos"), "ť": ("t", "apos"),
    "Á": ("A", "acute"), "Č": ("C", "caron"), "Ď": ("D", "caron"), "É": ("E", "acute"),
    "Ě": ("E", "caron"), "Í": ("I", "acute"), "Ň": ("N", "caron"), "Ó": ("O", "acute"),
    "Ř": ("R", "caron"), "Š": ("S", "caron"), "Ť": ("T", "caron"), "Ú": ("U", "acute"),
    "Ů": ("U", "ring"), "Ý": ("Y", "acute"), "Ž": ("Z", "caron"),
}

FONT_H = 11
FONT_BASE = 9


def glyph_bitmap(ch: str) -> list[list[int]]:
    accent = None
    if ch in ACCENTED:
        base, accent = ACCENTED[ch]
    else:
        base = ch
    rows = GLYPHS[base]
    w = len(rows[0])
    if accent == "apos":
        w += 2
    elif base == "ı" and accent:
        w = 2
    bm = [[0] * w for _ in range(FONT_H)]
    for y, row in enumerate(rows):
        for x, v in enumerate(row):
            if v == "#":
                bm[y + 2][x] = 1
    upper = base.isupper()
    y0 = 0 if upper else 2
    gw = len(rows[0])
    cx = (gw - 1) // 2
    if accent == "acute":
        if base == "ı":
            bm[y0][1] = 1
            bm[y0 + 1][1] = 0
        else:
            bm[y0][cx + 1] = 1
            bm[y0 + 1][cx] = 1
    elif accent == "caron":
        bm[y0][cx - 1] = 1
        bm[y0][cx + 1] = 1
        bm[y0 + 1][cx] = 1
    elif accent == "ring":
        if upper:
            bm[y0][cx] = 1
            bm[y0 + 1][cx - 1] = 1
            bm[y0 + 1][cx + 1] = 1
        else:
            for dx in (0, 1):
                for dy in (0, 1):
                    bm[y0 + dy][cx + dx] = 1
    elif accent == "apos":
        bm[2][w - 1] = 1
        bm[3][w - 1] = 1
    return bm


def gen_font() -> None:
    chars = list(GLYPHS.keys()) + list(ACCENTED.keys())
    chars = [ch for ch in chars if ch != "ı"]
    atlas_w = 256
    x = y = 1
    placed = []
    for ch in chars:
        bm = glyph_bitmap(ch)
        w = len(bm[0])
        if x + w + 1 > atlas_w:
            x = 1
            y += FONT_H + 1
        placed.append((ch, x, y, bm))
        x += w + 1
    atlas_h = 1
    while atlas_h < y + FONT_H + 1:
        atlas_h *= 2
    img = new(atlas_w, atlas_h)
    lines = [
        'info face="Bureau" size=12 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1 outline=0',
        f"common lineHeight=12 base={FONT_BASE} scaleW={atlas_w} scaleH={atlas_h} pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0",
        'page id=0 file="bureau.png"',
        f"chars count={len(placed)}",
    ]
    for ch, gx, gy, bm in placed:
        w = len(bm[0])
        for yy in range(FONT_H):
            for xx in range(w):
                if bm[yy][xx]:
                    img.putpixel((gx + xx, gy + yy), (255, 255, 255, 255))
        adv = w + 1
        lines.append(
            f"char id={ord(ch)} x={gx} y={gy} width={w} height={FONT_H} xoffset=0 yoffset=0 xadvance={adv} page=0 chnl=15"
        )
    (OUT / "fonts").mkdir(parents=True, exist_ok=True)
    img.save(OUT / "fonts" / "bureau.png")
    (OUT / "fonts" / "bureau.fnt").write_text("\n".join(lines) + "\n", encoding="utf-8")


# --- Rámy (9-slice) ---------------------------------------------------------

def bevel_box(w, h, fill, light, dark, outline="K0"):
    img = new(w, h)
    rect(img, 0, 0, w - 1, h - 1, outline)
    rect(img, 1, 1, w - 2, h - 2, fill)
    hline(img, 1, w - 2, 1, light)
    vline(img, 1, 1, h - 2, light)
    hline(img, 1, w - 2, h - 2, dark)
    vline(img, w - 2, 1, h - 2, dark)
    return img


def gen_panel_frame() -> None:
    """Ocelový rám bočních panelů s nýty."""
    w = h = 24
    img = bevel_box(w, h, "K2", "G1", "K1")
    rect(img, 3, 3, w - 4, h - 4, "K1")
    hline(img, 3, w - 4, 3, "K0")
    vline(img, 3, 3, h - 4, "K0")
    for (x, y) in [(2, 2), (w - 3, 2), (2, h - 3), (w - 3, h - 3)]:
        px(img, x, y, "G3")
    save(img, "ui/panel_frame.png")

    # Varianta pro úředníka (rudý lem) a hráče (modrý lem).
    for name, accent in (("panel_enemy", "R1"), ("panel_player", "B1")):
        im = img.copy()
        hline(im, 4, w - 5, 1, accent)
        hline(im, 4, w - 5, h - 2, accent)
        save(im, f"ui/{name}.png")


def gen_plaque() -> None:
    """Mosazná cedulka (hlavička, štítky)."""
    w, h = 24, 16
    img = bevel_box(w, h, "Y0", "Y1", "W0")
    rect(img, 2, 2, w - 3, h - 3, "W1")
    hline(img, 2, w - 3, 2, "W0")
    for (x, y) in [(3, 3), (w - 4, 3), (3, h - 4), (w - 4, h - 4)]:
        px(img, x, y, "Y2")
    save(img, "ui/plaque.png")

    img = bevel_box(w, h, "K2", "K3", "K0")
    rect(img, 2, 2, w - 3, h - 3, "K1")
    save(img, "ui/plaque_dark.png")


def noise_fill(img, x0, y0, x1, y1, base, spots, density, seed):
    rnd = random.Random(seed)
    rect(img, x0, y0, x1, y1, base)
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if rnd.random() < density:
                px(img, x, y, rnd.choice(spots))


def gen_desks() -> None:
    # Úřednická strana: zelené linoleum za sklem, šikmé odlesky.
    w = h = 48
    img = new(w, h)
    rect(img, 0, 0, w - 1, h - 1, "K0")
    noise_fill(img, 1, 1, w - 2, h - 2, "O1", ["O0", "O2"], 0.10, 1)
    for i in range(-h, w, 16):
        for t in range(h):
            x = i + t
            if 1 <= x < w - 1 and 1 <= t < h - 1:
                px(img, x, t, "O2")
                if 1 <= x + 1 < w - 1:
                    px(img, x + 1, t, "O2")
    hline(img, 1, w - 2, 1, "O3")
    hline(img, 1, w - 2, h - 2, "O0")
    save(img, "ui/desk_enemy.png")

    # Strana občana: dřevěný stůl s léty.
    img = new(w, h)
    rect(img, 0, 0, w - 1, h - 1, "K0")
    rect(img, 1, 1, w - 2, h - 2, "W1")
    rnd = random.Random(7)
    for y in range(1, h - 1):
        if y % 6 in (0,):
            hline(img, 1, w - 2, y, "W0")
        elif y % 6 == 3:
            for x in range(1, w - 1):
                if rnd.random() < 0.6:
                    px(img, x, y, "W2")
    for _ in range(6):
        kx, ky = rnd.randrange(4, w - 6), rnd.randrange(4, h - 4)
        px(img, kx, ky, "W0")
        px(img, kx + 1, ky, "W0")
        px(img, kx - 1, ky - 1, "W2")
        px(img, kx + 2, ky + 1, "W2")
    hline(img, 1, w - 2, 1, "W3")
    hline(img, 1, w - 2, h - 2, "W0")
    save(img, "ui/desk_player.png")


def gen_counter() -> None:
    """Hrana přepážky mezi úředníkem a hráčem."""
    w, h = 16, 12
    img = new(w, h)
    rect(img, 0, 0, w - 1, h - 1, "K0")
    rect(img, 0, 1, w - 1, 3, "G3")
    hline(img, 0, w - 1, 1, "G4")
    rect(img, 0, 4, w - 1, 8, "G1")
    hline(img, 0, w - 1, 4, "G2")
    rect(img, 0, 9, w - 1, 10, "K2")
    for x in range(0, w, 4):
        px(img, x, 6, "K3")
    save(img, "ui/counter.png")

    # Cedulka "PŘEPÁŽKA" uprostřed hrany.
    w, h = 20, 14
    img = bevel_box(w, h, "R1", "R2", "R0")
    save(img, "ui/counter_sign.png")


def gen_slots() -> None:
    w = h = 24

    def tray(edge, corner, fill="K1"):
        img = new(w, h)
        rect(img, 0, 0, w - 1, h - 1, "K0")
        rect(img, 1, 1, w - 2, h - 2, fill)
        hline(img, 1, w - 2, 1, "K0")
        vline(img, 1, 1, h - 2, "K0")
        hline(img, 2, w - 2, h - 2, edge)
        vline(img, w - 2, 2, h - 2, edge)
        # rohové značky
        for (x, y, dx, dy) in [(3, 3, 1, 1), (w - 4, 3, -1, 1), (3, h - 4, 1, -1), (w - 4, h - 4, -1, -1)]:
            px(img, x, y, corner)
            px(img, x + dx, y, corner)
            px(img, x + 2 * dx, y, corner)
            px(img, x, y + dy, corner)
            px(img, x, y + 2 * dy, corner)
        return img

    save(tray("O2", "R1", "O0"), "ui/slot_enemy.png")
    save(tray("W2", "B2", "W0"), "ui/slot_player.png")
    img = tray("Y1", "Y2", "W1")
    rect(img, 0, 0, w - 1, 0, "Y1")
    rect(img, 0, h - 1, w - 1, h - 1, "Y1")
    vline(img, 0, 0, h - 1, "Y1")
    vline(img, w - 1, 0, h - 1, "Y1")
    save(img, "ui/slot_valid.png")


def with_shadow(img: Image.Image) -> Image.Image:
    """Přidá vpravo dole stín 1 px (obrázek se o 1 px zvětší)."""
    out = new(img.width + 1, img.height + 1)
    alpha = img.getchannel("A")
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 110))
    out.paste(shadow, (1, 1), alpha)
    out.alpha_composite(img)
    return out


def gen_cards() -> None:
    # Hráčova karta: úřední papír se zahnutým rohem. 9-slice okraje 6.
    w = h = 24
    img = new(w, h)
    rect(img, 0, 0, w - 1, h - 1, "K0")
    rect(img, 1, 1, w - 2, h - 2, "P3")
    hline(img, 1, w - 2, 1, "P4")
    vline(img, 1, 1, h - 2, "P4")
    hline(img, 2, w - 2, h - 2, "P1")
    vline(img, w - 2, 2, h - 2, "P1")
    # zahnutý roh vpravo nahoře
    for i in range(5):
        for j in range(5 - i):
            px(img, w - 1 - j, i, CLEAR)
    for i in range(5):
        px(img, w - 6 + i, i, "K0")
    for i in range(1, 5):
        for j in range(i):
            px(img, w - 6 + j + 1, i, "P1")
    px(img, w - 6, 0, "K0")
    vline(img, w - 1, 5, h - 1, "K0")
    save(with_shadow(img), "ui/card_player.png")

    # Úředníkova karta: služební průkaz, šedomodrý s rudým pruhem nahoře.
    img = new(w, h)
    rect(img, 0, 0, w - 1, h - 1, "K0")
    rect(img, 1, 1, w - 2, h - 2, "G4")
    rect(img, 1, 1, w - 2, 4, "R1")
    hline(img, 1, w - 2, 1, "R2")
    hline(img, 1, w - 2, 5, "K2")
    hline(img, 2, w - 2, h - 2, "G3")
    vline(img, w - 2, 6, h - 2, "G3")
    vline(img, 1, 6, h - 2, "P4")
    save(with_shadow(img), "ui/card_enemy.png")

    # Rub karty: úřední pečeť na tmavě rudém podkladu, 80x52 i se stínem.
    w, h = 79, 51
    img = new(w, h)
    rect(img, 0, 0, w - 1, h - 1, "K0")
    rect(img, 1, 1, w - 2, h - 2, "R0")
    for y in range(2, h - 2):
        for x in range(2, w - 2):
            if (x + y) % 6 == 0:
                px(img, x, y, "R1")
    for x in range(3, w - 3):
        px(img, x, 3, "Y0")
        px(img, x, h - 4, "Y0")
    for y in range(3, h - 3):
        px(img, 3, y, "Y0")
        px(img, w - 4, y, "Y0")
    cx, cy, r = w // 2, h // 2, 14
    d = ImageDraw.Draw(img)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c("K0"))
    d.ellipse([cx - r + 1, cy - r + 1, cx + r - 1, cy + r - 1], fill=c("Y0"))
    d.ellipse([cx - r + 3, cy - r + 3, cx + r - 3, cy + r - 3], fill=c("R1"))
    d.ellipse([cx - r + 4, cy - r + 4, cx + r - 4, cy + r - 4], fill=c("R0"))
    para = [
        "..###..",
        ".#...#.",
        ".#.....",
        "..###..",
        ".#...#.",
        "..###..",
        ".....#.",
        ".#...#.",
        "..###..",
    ]
    for yy, row in enumerate(para):
        for xx, v in enumerate(row):
            if v == "#":
                px(img, cx - 3 + xx, cy - 4 + yy, "Y1")
    save(with_shadow(img), "ui/card_back.png")
    # Malý rub pro ruku úředníka kreslíme zvlášť, zmenšení by zničilo pixely.
    sw, sh = 23, 30
    small = new(sw, sh)
    rect(small, 0, 0, sw - 1, sh - 1, "K0")
    rect(small, 1, 1, sw - 2, sh - 2, "R0")
    for y in range(2, sh - 2):
        for x in range(2, sw - 2):
            if (x + y) % 4 == 0:
                px(small, x, y, "R1")
    for x in range(2, sw - 2):
        px(small, x, 2, "Y0")
        px(small, x, sh - 3, "Y0")
    for y in range(2, sh - 2):
        px(small, 2, y, "Y0")
        px(small, sw - 3, y, "Y0")
    d = ImageDraw.Draw(small)
    d.ellipse([sw // 2 - 5, sh // 2 - 5, sw // 2 + 5, sh // 2 + 5], fill=c("Y0"))
    d.ellipse([sw // 2 - 3, sh // 2 - 3, sw // 2 + 3, sh // 2 + 3], fill=c("R0"))
    px(small, sw // 2, sh // 2, "Y1")
    save(small, "ui/card_back_small.png")


def gen_buttons() -> None:
    """Velké razítkové tlačítko. 9-slice okraje 6."""
    w, h = 32, 24

    def btn(face, light, dark, press=False, text_bg=None):
        img = new(w, h)
        top = 2 if press else 0
        # stín pod tlačítkem
        if not press:
            rect(img, 1, 3, w - 1, h - 1, "K0")
        rect(img, 0, top, w - 2, h - 3 + top, "K0")
        rect(img, 1, top + 1, w - 3, h - 4 + top, face)
        hline(img, 1, w - 3, top + 1, light)
        vline(img, 1, top + 1, h - 4 + top, light)
        hline(img, 2, w - 3, h - 4 + top, dark)
        vline(img, w - 3, top + 2, h - 4 + top, dark)
        # vnitřní linka razítka
        for x in range(3, w - 4):
            px(img, x, top + 3, dark)
            px(img, x, h - 6 + top, dark)
        for y in range(top + 3, h - 5 + top):
            px(img, 3, y, dark)
            px(img, w - 5, y, dark)
        return img

    save(btn("R2", "R3", "R1"), "ui/btn_normal.png")
    save(btn("R3", "Y2", "R2"), "ui/btn_hover.png")
    save(btn("R1", "R2", "R0", press=True), "ui/btn_pressed.png")
    save(btn("G1", "G2", "K3", press=True), "ui/btn_disabled.png")


def gen_bars() -> None:
    w, h = 8, 8
    img = new(w, h)
    rect(img, 0, 0, w - 1, h - 1, "K0")
    rect(img, 1, 1, w - 2, h - 2, "K1")
    hline(img, 1, w - 2, 1, "K0")
    save(img, "ui/bar_bg.png")
    for name, (base, light, dark) in {
        "bar_red": ("R2", "R3", "R1"),
        "bar_green": ("H1", "H2", "H0"),
        "bar_gold": ("Y0", "Y1", "W0"),
    }.items():
        img = new(w, h)
        rect(img, 0, 0, w - 1, h - 1, base)
        hline(img, 0, w - 1, 0, light)
        hline(img, 0, w - 1, 1, light)
        hline(img, 0, w - 1, h - 1, dark)
        save(img, f"ui/{name}.png")
    # Malý pruh pro karty
    w, h = 4, 4
    img = new(w, h)
    rect(img, 0, 0, w - 1, h - 1, "K0")
    rect(img, 1, 1, w - 2, h - 2, "K2")
    save(img, "ui/bar_small_bg.png")
    img = new(w, h)
    rect(img, 0, 0, w - 1, h - 1, "H1")
    hline(img, 0, w - 1, 0, "H3")
    save(img, "ui/bar_small_fill.png")


def gen_paper() -> None:
    """Papír protokolu (log) s perforací po stranách."""
    w = h = 24
    img = new(w, h)
    rect(img, 0, 0, w - 1, h - 1, "K0")
    rect(img, 1, 1, w - 2, h - 2, "P3")
    for y in range(4, h - 4, 4):
        px(img, 3, y, "P1")
        px(img, w - 4, y, "P1")
    hline(img, 1, w - 2, h - 2, "P1")
    hline(img, 1, w - 2, 1, "P4")
    save(img, "ui/paper.png")


def gen_stamp() -> None:
    """Rám velkého razítka (bílý, barví se v Godotu přes modulate)."""
    w = h = 24
    img = new(w, h)
    white = (255, 255, 255, 255)
    for i in (0, 1, 4):
        ImageDraw.Draw(img).rectangle([i, i, w - 1 - i, h - 1 - i], outline=white)
    # opotřebené razítko: pár vynechaných pixelů
    for (x, y) in [(7, 0), (15, 1), (0, 9), (23, 14), (11, 23), (4, 18), (19, 4)]:
        img.putpixel((x, y), CLEAR)
    save(img, "ui/stamp_frame.png")


def gen_hand_strip() -> None:
    """Tmavý pruh pod rukou (okraj hráčova stolu)."""
    w, h = 16, 16
    img = new(w, h)
    rect(img, 0, 0, w - 1, h - 1, "K1")
    hline(img, 0, w - 1, 0, "K0")
    hline(img, 0, w - 1, 1, "W1")
    hline(img, 0, w - 1, 2, "K0")
    save(img, "ui/hand_strip.png")


# --- Ikony ------------------------------------------------------------------
ICON_LEGEND = {
    "k": "K0", "p": "P3", "P": "P1", "l": "K3", "r": "R2", "R": "R1", "w": "P4",
    "y": "Y1", "Y": "Y0", "b": "B2", "B": "B1", "g": "G2", "G": "G3", "o": "W2",
    "O": "W1", "s": "S1", "S": "S2", "a": "K2", "e": "K0", "c": "N2", "C": "B3",
    "q": "P2", "Q": "P1", "h": "H2", "H": "H1", "n": "N1", "i": "PK", "I": "PD",
}

SMALL_ICONS = {
    "atk": [
        "..kkkk..",
        "..kook..",
        "..kOOk..",
        "...kk...",
        ".kkkkkk.",
        "kooooook",
        "kRRRRRRk",
        ".kkkkkk.",
    ],
    "hp": [
        ".kk.kk..",
        "kwrkrrk.",
        "krrrrrk.",
        "krrrrrk.",
        ".krrrk..",
        "..krk...",
        "...k....",
        "........",
    ],
    "deck": [
        "..kkkkk.",
        ".kkpppk.",
        "kkpkkkk.",
        "kpkpppk.",
        "kpkplpk.",
        "kpkpppk.",
        "kkkpppk.",
        "..kkkkk.",
    ],
    "energy_on": [
        "...kkkkkk...",
        "..kwyyyyyk..",
        ".kwyyyyyyYk.",
        "kwyyYYYYyyYk",
        "kyyYyyyyYyYk",
        "kyyYyYYyYyYk",
        "kyyYyYYyYyYk",
        "kyyYyyyyYyYk",
        "kyyyYYYYyyYk",
        ".kyyyyyyyYk.",
        "..kYYYYYYk..",
        "...kkkkkk...",
    ],
    "energy_off": [
        "...kkkkkk...",
        "..kaaaaaak..",
        ".kaaaaaaaak.",
        "kaaallllaaak",
        "kaalaaaalaak",
        "kaalallalaak",
        "kaalallalaak",
        "kaalaaaalaak",
        "kaaallllaaak",
        ".kaaaaaaaak.",
        "..kaaaaaak..",
        "...kkkkkk...",
    ],
}

SMALL_ICONS["energy_lost"] = [
    "...kkkkkk...",
    "..kaaaaaak..",
    ".kaRaaaaRak.",
    "kaaRRaaRRaak",
    "kaaaRRRRaaak",
    "kaaaaRRaaaak",
    "kaaaaRRaaaak",
    "kaaaRRRRaaak",
    "kaaRRaaRRaak",
    ".kaRaaaaRak.",
    "..kaaaaaak..",
    "...kkkkkk...",
]

# Groš: měděná mince se čtvercovou dírou (vlastní legenda).
GROSE_ICON = [
    "...kkkkkk...",
    "..kyyyyyYk..",
    ".kywyyyyyYk.",
    "kywyyyyyyyYk",
    "kyyyykkyyyYk",
    "kyyykOOkyyYk",
    "kyyykOOkyyYk",
    "kyyyykkyyyYk",
    "kyyyyyyyyyYk",
    ".kyyyyyyyYk.",
    "..kYYYYYYk..",
    "...kkkkkk...",
]

CARD_ICONS = {
    "paw": [
        "................",
        ".....kk.kk......",
        "..kk.kikkik.kk..",
        ".kiikkikkikkiik.",
        ".kiikkikkikkiik.",
        ".kiikkikkikkiik.",
        "..kiiiiiiiiiiik.",
        "..kiiiiiiiiiIk..",
        "...kiiiiiiiIIk..",
        "...kiiiiiiIIk...",
        "....kiiiiIIk....",
        "....kkkkkkkk....",
        "....kRRrRRRk....",
        "....kRrRRrRk....",
        ".....kkkkkk.....",
        "................",
    ],
    "prosthesis": [
        "......kkkk......",
        ".....kGGGGk.....",
        "....kGk..kGk....",
        "....kGk...kk....",
        "....kGk.........",
        ".....kGk........",
        "......kGk.......",
        "......kGk.......",
        "....kkkGkkk.....",
        "...kOOOOOOOk....",
        "...kOyOOOyOk....",
        "...kOOOOOOOk....",
        "...kOOOOOOOk....",
        "...kOyOOOyOk....",
        "...kkkkkkkkk....",
        "................",
    ],
    "form": [
        "..kkkkkkkkkk....",
        "..kpppppppPkk...",
        "..kpllllpppPPk..",
        "..kpppppppppPPk.",
        "..kplllllllpppk.",
        "..kpppppppppppk.",
        "..kpkkpllllllpk.",
        "..kpkrkppppppPk.",
        "..kpkkpllllllpk.",
        "..kpppppppppppk.",
        "..kpkkplllllppk.",
        "..kpkkpppppppPk.",
        "..kppppppprrpPk.",
        "..kpppppprrppPk.",
        "..kPPPPPPPPPPPk.",
        "..kkkkkkkkkkkkk.",
    ],
    "stamp": [
        "......kkkk......",
        ".....kooook.....",
        ".....kooOok.....",
        ".....kooOok.....",
        "......kOOk......",
        "......kOOk......",
        "......kOOk......",
        "....kkkkkkkk....",
        "...kooooooOOk...",
        "...kOOOOOOOOk...",
        "..kkkkkkkkkkkk..",
        "..kRRRRRRRRRRk..",
        "..kkkkkkkkkkkk..",
        "................",
        "..rr.rrr.r.rr...",
        "...r..r.rr..r...",
    ],
    "envelope": [
        "................",
        "................",
        "kkkkkkkkkkkkkkkk",
        "kPkppppppppppkPk",
        "kppkppppppppkppk",
        "kpppkppppppkpppk",
        "kppppkppppkppppk",
        "kpppppkrrkpppppk",
        "kppppppkRkppppPk",
        "kpppppppkppppppk",
        "kpppppppppppppPk",
        "kPPPPPPPPPPPPPPk",
        "kkkkkkkkkkkkkkkk",
        "................",
        "......kkkkk.....",
        "......kRkRk.....",
    ],
    "hourglass": [
        "..kkkkkkkkkkkk..",
        "..kOooooooooOk..",
        "..kkkkkkkkkkkk..",
        "...kCyyyyyyCk...",
        "...kCCyyyyCCk...",
        "....kCCyyCCk....",
        ".....kCyyCk.....",
        "......kyyk......",
        ".....kCCyCk.....",
        "....kCCCyCCk....",
        "...kCCCyyyCCk...",
        "...kCyyyyyyCk...",
        "..kkkkkkkkkkkk..",
        "..kOooooooooOk..",
        "..kkkkkkkkkkkk..",
        "................",
    ],
    "copies": [
        "kkkkkkkkk.......",
        "kGGGGGGGkk......",
        "kGllllGGGGk.....",
        "kGGGkkkkkkkkk...",
        "kGllkpppppppkk..",
        "kGGGkpllllpppPk.",
        "kGllkppppppppPk.",
        "kGGGkplllllllpk.",
        "kGllkpppppppppk.",
        "kGGGkplllllllpk.",
        "kkkkkpppppppppk.",
        "....kplllllpppk.",
        "....kpppppppppk.",
        "....kPPPPPPPPPk.",
        "....kkkkkkkkkkk.",
        "................",
    ],
    "magnifier": [
        "...kkkkk........",
        "..kgggggk.......",
        ".kgcccwwgk......",
        "kgccccwwcgk.....",
        "kgcccccwcgk.....",
        "kgcccccccgk.....",
        "kgcccccccgk.....",
        ".kgcccccgk......",
        "..kgggggkk......",
        "...kkkkkOOk.....",
        "........kOOk....",
        ".........kOOk...",
        "..........kOOk..",
        "...........kOOk.",
        "............kkk.",
        "................",
    ],
    "pen": [
        "............kk..",
        "...........kbbk.",
        "..........kbBk..",
        ".........kbBk...",
        "........kbBk..c.",
        ".......kbBk..ccc",
        "......kbBk...ccc",
        ".....kbBk.....c.",
        "....kyBk........",
        "....kyk.........",
        "...kkk..........",
        "..k.............",
        "................",
        ".l..ll.l..l.ll..",
        "l.ll..l.ll.l..l.",
        "................",
    ],
    "certified": [
        "..kkkkkkkkkkk...",
        "..kppppppppPPk..",
        "..kpllllllpppk..",
        "..kppppppppppk..",
        "..kplllllllppk..",
        "..kppppppppppk..",
        "..kplllllpppPk..",
        "..kpppppkkkPPk..",
        "..kppppkyyykPk..",
        "..kpppkyyYyykk..",
        "..kpppkyYyYyk...",
        "..kpppkyyYyyk...",
        "..kPPPPkyyyk....",
        "..kkkkkrkkkrk...",
        ".......rk.kr....",
        ".......r...r....",
    ],
    "complaint": [
        "..kkkkkkkkkkkk..",
        ".kwwwwwwwwwwwwk.",
        "kwwwwwwkkwwwwwwk",
        "kwwwwwkrrkwwwwwk",
        "kwwwwwkrrkwwwwwk",
        "kwwwwwkrrkwwwwwk",
        "kwwwwwkRRkwwwwwk",
        "kwwwwwwkkwwwwwwk",
        "kwwwwwkrrkwwwwwk",
        "kwwwwwwkkwwwwwwk",
        ".kwwwwwwwwwwwwk.",
        "..kkkkwwkkkkkk..",
        ".....kwk........",
        "....kwk.........",
        "....kk..........",
        "................",
    ],
    "folder": [
        "................",
        ".kkkkk..........",
        "kqqqqqk.........",
        "kqqqqqqkkkkkkkk.",
        "kQQQQQQQQQQQQQQk",
        "kqqqqqqqqqqqqqqk",
        "kqqqkkkkkkkkqqqk",
        "kqqqkwlllwwkqqqk",
        "kqqqkkkkkkkkqqqk",
        "kqqqqqqqqqqqqqqk",
        "kqqqqqqqqqqqqqqk",
        "kqqqqqqqqqqqqqqk",
        "kQQQQQQQQQQQQQQk",
        "kkkkkkkkkkkkkkkk",
        "................",
        "................",
    ],
}

# Úředníci: levé poloviny 8x16, zrcadlí se. Barvy podle legendy varianty.
FACE_HALVES = {
    "referent": [  # brýle, hnědé vlasy, modrá kravata
        "........",
        "....kkkk",
        "...kaaaa",
        "..kaaaaa",
        "..kaasss",
        "..ksssss",
        ".kkgggss",
        "..kgwegg",
        "..kSssss",
        "...kSsss",
        "...kSsrr",
        "....kkSS",
        "..kkjjkc",
        ".kjjjjkt",
        "kjjjjjkt",
        "kjjjjjjt",
    ],
    "revizor": [  # čepice s odznakem, knír
        "....kkkk",
        "...kjjjj",
        "..kjjjjy",
        ".kkkkkkk",
        "..ksssss",
        "..ksssss",
        "..ksseks",
        "..kSssss",
        "..kSssss",
        "...kSmmm",
        "...kSsrr",
        "....kkSS",
        "..kkjjkc",
        ".kjjjjkt",
        "kjjjjjkt",
        "kjjjjjjt",
    ],
    "vedouci": [  # pleš, šedé boky, zlatá kravata, úsměšek
        "........",
        "....kkkk",
        "...kssss",
        "..ksssss",
        "..kassss",
        ".kaassss",
        ".kassekk",
        ".kaSssss",
        "..kSssss",
        "..kSSsss",
        "...kSsss",
        "....kSrr",
        "..kkkkkc",
        ".kjjjjkt",
        "kjjjjjkt",
        "kjjjjjjt",
    ],
    "podatelna": [  # kulaté brýle, svetr, bez kravaty
        "........",
        "....kkkk",
        "...kaaaa",
        "..kaaaaa",
        "..kasaaa",
        "..ksssss",
        "..kgggss",
        "..gwegsg",
        "..kgggss",
        "...kSsss",
        "...kSsss",
        "....kSrr",
        "..kkjjkk",
        ".kjjjjjc",
        "kjjjjjjc",
        "kjjjjjjj",
    ],
    "kontrolor": [  # sluneční brýle, uhlazené vlasy, černý oblek
        "........",
        "....kkkk",
        "...kaaaa",
        "..kaaaaa",
        "..kaaaaa",
        "..ksssss",
        "..kkkkkk",
        "..kkkkck",
        "..kSssss",
        "...kSsss",
        "...kSsrr",
        "....kkSS",
        "..kkjjkc",
        ".kjjjjkt",
        "kjjjjjkt",
        "kjjjjjjt",
    ],
}

FACE_COLORS = {
    "referent": {"a": "W1", "j": "G1", "t": "B2", "g": "K0", "w": "G4"},
    "revizor": {"a": "W1", "j": "B1", "t": "R2", "y": "Y1", "m": "W0"},
    "vedouci": {"a": "G3", "j": "K2", "t": "Y1"},
    "podatelna": {"a": "W0", "j": "O3", "t": "O3", "g": "K0", "w": "G4"},
    "kontrolor": {"a": "K0", "j": "K1", "t": "R1", "c": "N2"},
}


def gen_icons() -> None:
    for name, rows in SMALL_ICONS.items():
        save(from_ascii(rows, ICON_LEGEND), f"icons/{name}.png")
    save(from_ascii(GROSE_ICON, {"k": "K0", "y": "W3", "Y": "W1", "w": "Y1", "O": "K1"}), "icons/grose.png")
    for name, rows in CARD_ICONS.items():
        save(from_ascii(rows, ICON_LEGEND, 16), f"icons/card_{name}.png")
    base = {"k": "K0", "s": "S1", "S": "S2", "e": "K0", "r": "R1", "c": "G4", "w": "G4", "g": "K0"}
    for name, half in FACE_HALVES.items():
        legend = dict(base)
        legend.update(FACE_COLORS[name])
        rows = mirror(half)
        # Asymetrické detaily
        if name == "kontrolor":
            rows[7] = rows[7][:9] + "c" + rows[7][10:]
        img = from_ascii(rows, legend, 16)
        save(img, f"icons/card_{name}.png")


# --- Portréty 40x40 ---------------------------------------------------------
# --- Pozadí 640x360 ---------------------------------------------------------

def gen_background() -> None:
    w, h = 640, 360
    img = new(w, h)
    # obloha: tmavě fialová, k obzoru růžovější smog
    bands = ["K0", "K1", "K2", "K3", "#4a2d55"]
    for y in range(h):
        t = min(y / 260, 0.999) * (len(bands) - 1)
        i = int(t)
        f = t - i
        for x in range(w):
            col = bands[min(i + 1, len(bands) - 1)] if dither(x, y, f) else bands[i]
            px(img, x, y, col)

    rnd = random.Random(42)
    # hvězdy / drony
    for _ in range(70):
        px(img, rnd.randrange(w), rnd.randrange(120), rnd.choice(["G2", "G3", "N2"]))

    def tower(x0, width, top, body, window_cols, lit_p, antenna=False, neon=None):
        rect(img, x0, top, x0 + width - 1, h - 1, body)
        vline(img, x0, top, h - 1, "K0")
        if antenna:
            ax = x0 + width // 2
            vline(img, ax, top - 14, top, body)
            px(img, ax, top - 15, "R3")
        for wy in range(top + 3, h - 2, 4):
            for wx in range(x0 + 2, x0 + width - 2, 3):
                if rnd.random() < lit_p:
                    px(img, wx, wy, rnd.choice(window_cols))
        if neon:
            ny = top + rnd.randrange(8, 30)
            rect(img, x0 + 2, ny, x0 + width - 3, ny + 3, "K0")
            hline(img, x0 + 3, x0 + width - 4, ny + 1, neon)
            hline(img, x0 + 3, x0 + width - 4, ny + 2, neon)

    # vzdálené věže (futuristické, nahoře bohatí)
    x = 0
    while x < w:
        wd = rnd.randrange(14, 30)
        top = rnd.randrange(30, 110)
        tower(x, wd, top, "#2a2140", ["#5a4a7a", "N2"], 0.25, antenna=rnd.random() < 0.3)
        x += wd + rnd.randrange(0, 6)
    # dominantní věž ve středu
    tower(300, 40, 12, "#2a2140", ["Y2", "N2"], 0.4, antenna=True)
    # střední vrstva
    x = -10
    while x < w:
        wd = rnd.randrange(24, 50)
        top = rnd.randrange(130, 200)
        tower(x, wd, top, "K1", ["Y1", "Y0", "N1"], 0.18, neon=rnd.choice([None, "N1", "N2", None]))
        x += wd + rnd.randrange(2, 10)
    # blízká vrstva (ulice dole)
    x = -5
    while x < w:
        wd = rnd.randrange(40, 80)
        top = rnd.randrange(240, 290)
        tower(x, wd, top, "K0", ["Y0", "R1"], 0.12)
        x += wd + rnd.randrange(0, 4)
    # mlha na ulici
    for y in range(300, h):
        f = (y - 300) / 60
        for x in range(w):
            if dither(x, y, f * 0.5):
                px(img, x, y, "K2")
    save(img, "bg/city.png")


def main() -> None:
    # Pomocné barvy zadané přímo hexem
    for hexcol in ["#4a2d55", "#2a2140", "#5a4a7a"]:
        PAL[hexcol] = hexcol
    gen_font()
    gen_panel_frame()
    gen_plaque()
    gen_desks()
    gen_counter()
    gen_slots()
    gen_cards()
    gen_buttons()
    gen_bars()
    gen_paper()
    gen_hand_strip()
    gen_stamp()
    gen_icons()
    gen_background()
    import gen_world  # scény města a baru
    import gen_characters  # animované portréty postav

    gen_world.main()
    gen_characters.main()
    print("assets ->", OUT)


if __name__ == "__main__":
    main()
