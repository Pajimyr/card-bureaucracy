"""Animované portréty postav (40x40, ve hře 2x nebo 4x).

Každá postava má sheet 8 snímků vedle sebe:
    idle_0, idle_1, blink_0, blink_1, talk_0, talk_1, hurt_0, hurt_1
_0/_1 je fáze dechu (ramena se zvednou o pixel). portraits/<jméno>.png je idle_0
pro místa, kde stačí statický obrázek. Úředník má navíc portraits/official_smoke.png
(4 snímky kouře z cigarety, vrství se přes portrét).

Postavy jsou zobrazené bez příkras: pot, rozkousané zuby, jizvy, flekaté oblečení.
Volá se z gen_assets.py. Samostatně: python3 tools/gen_characters.py
"""
from __future__ import annotations

import random

from PIL import Image, ImageDraw

import gen_assets as ga
from gen_assets import c, dither, from_ascii, hline, mirror, new, px, rect, save, vline

for _hex, _val in {
    "SW": "#a8d8f0",  # pot
    "TY": "#c8b060",  # zažloutlé zuby
    "TR": "#8a7438",  # shnilé zuby
    "SK": "#cfa27a",  # nažloutlá kůže
    "SKD": "#9a6a48",
    "WH": "#e8dccc",  # bělmo
    "#2a1a10": "#2a1a10",
    "#4a2d55": "#4a2d55",
}.items():
    ga.PAL[_hex] = _val

STATES = ["idle", "blink", "talk", "hurt"]
SIZE = 40


def grid(half: list[str]) -> list[list[str]]:
    rows = [r.ljust(20, ".")[:20] for r in half]
    return [list(r) for r in mirror(rows)]


def put(rows, pts, ch):
    for x, y in pts:
        if 0 <= x < SIZE and 0 <= y < SIZE:
            rows[y][x] = ch


def both(pts):
    """Body na levé půlce + jejich zrcadlo na pravé."""
    return list(pts) + [(SIZE - 1 - x, y) for x, y in pts]


def span(x0, x1, y):
    return [(x, y) for x in range(x0, x1 + 1)]


def dither_on(rows, y0, y1, x0, x1, src, dst, parity=0):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if rows[y][x] == src and (x + y) % 2 == parity:
                rows[y][x] = dst


def breathe(rows, body_row):
    """Ramena a tělo o pixel nahoru: řádek body_row zmizí, spodní řádek se zopakuje."""
    return rows[:body_row] + rows[body_row + 1:] + [list(rows[-1])]


class Character:
    name = ""
    half: list[str] = []
    legend: dict[str, str] = {}
    body_row = 30

    def bg(self, img):
        pass

    def grit(self, rows):
        pass

    def blink(self, rows):
        pass

    def talk(self, rows):
        pass

    def hurt(self, rows):
        pass

    def frame(self, state: str, breath: int) -> Image.Image:
        rows = grid(self.half)
        self.grit(rows)
        if state != "idle":
            getattr(self, state)(rows)
        if breath:
            rows = breathe(rows, self.body_row)
        img = new(SIZE, SIZE)
        self.bg(img)
        img.alpha_composite(from_ascii(["".join(r) for r in rows], self.legend, SIZE))
        return img

    def generate(self):
        sheet = new(SIZE * 8, SIZE)
        i = 0
        for state in STATES:
            for breath in (0, 1):
                sheet.alpha_composite(self.frame(state, breath), (i * SIZE, 0))
                i += 1
        save(sheet, f"portraits/{self.name}_sheet.png")
        save(self.frame("idle", 0), f"portraits/{self.name}.png")


# --- Úředník: zpocený, krvavé oči za brýlemi, cigareta, flek od kafe ------------

class Official(Character):
    name = "official"
    body_row = 26
    half = [
        "....................",
        "....................",
        "....................",
        "............kkkkkkkk",
        "..........kkhhhsssss",
        ".........khhssssssss",
        "........khssssssssss",
        "........kassssssssss",
        ".......kaassssssssss",
        ".......kaaSsssssssss",
        ".......kaSskkkkkssss",
        ".......kaSgggggggsss",
        "......kkSsgviieigggg",
        "......ksSsgiiivigsss",
        ".......kSsgggggggsss",
        ".......kSsSSSSSsssSs",
        "........kSssssssssSS",
        "........kSsssssmmmmm",
        "........kSssssmmmmmm",
        "........kSSsssrrrrrr",
        ".........kSssrssssss",
        ".........kSSssssssss",
        "..........kSSsssssss",
        "...........kkSSSssss",
        ".............kkkSSSS",
        "..............kSSSSS",
        "..........kkkkkcSSSS",
        "......kkkkjjjkccccct",
        "....kkjjjjjjjjkccctt",
        "...kjjjjjjjjjjjkcctt",
        "..kjjjjjjjjjjjjjkctt",
        "..kjjLjjjjjjjjjjjkTt",
        ".kjjLjjjjjjjjjjjjkTt",
        ".kjjLjjjjjjjjjjjjjkt",
        ".kjjLjjjjjjjjjjjjjkt",
        "kjjjLjjjjjjjjjjjjJkt",
        "kjjjLjjjjjjjjjjjjJkT",
        "kjjjjjjjjjjjjjjjjJkT",
        "kjjjjjjjjjjjjjjjjJkk",
        "kjjjjjjjjjjjjjjjjJkk",
    ]
    legend = {
        "k": "K0", "s": "S1", "S": "S2", "h": "P3", "a": "G3", "g": "K0", "e": "K0",
        "i": "WH", "v": "R2", "m": "G2", "r": "R1", "R": "R0", "c": "G4", "t": "R2", "T": "R1",
        "j": "G1", "J": "K3", "L": "G2", "d": "S2", "o": "W1", "p": "S3", "q": "SW",
        "w": "P4", "x": "G3", "n": "R3", "y": "Y1",
    }

    def bg(self, img):
        for y in range(SIZE):
            for x in range(SIZE):
                px(img, x, y, "O2" if dither(x, y, y / 60) else "O1")
        # oprýskaná zeď: mapy vlhkosti
        for (x, y) in [(3, 20), (4, 21), (5, 20), (33, 26), (34, 27), (2, 30)]:
            px(img, x, y, "O0")
        rect(img, 2, 3, 10, 10, "K0")
        rect(img, 3, 4, 9, 9, "P1")
        hline(img, 4, 8, 5, "P0")
        hline(img, 4, 7, 7, "P0")
        px(img, 8, 8, "R1")
        rect(img, 34, 2, 39, 10, "K0")
        rect(img, 35, 3, 39, 9, "R0")
        vline(img, 37, 4, 8, "Y0")
        hline(img, 36, 38, 5, "Y0")
        hline(img, 36, 38, 7, "Y0")

    def grit(self, rows):
        # stařecké skvrny na pleši, pot na čele a spánku
        put(rows, [(15, 5), (16, 5), (23, 7), (14, 6)], "p")
        put(rows, [(12, 8), (12, 9), (29, 9), (29, 10), (21, 6)], "q")
        # strniště na bradě
        dither_on(rows, 20, 23, 10, 29, "s", "d")
        # cigareta v pravém koutku, popel a žhavý konec
        put(rows, span(25, 32, 19), "w")
        put(rows, [(33, 19)], "x")
        put(rows, [(34, 19)], "n")
        put(rows, [(34, 18)], "y")
        # flek od kafe na košili, povolená kravata
        put(rows, [(16, 28), (17, 28), (17, 29)], "o")
        put(rows, [(22, 27), (22, 28)], "c")

    def blink(self, rows):
        put(rows, both(span(11, 15, 12)), "S")
        put(rows, both(span(11, 15, 13)), "k")

    def talk(self, rows):
        put(rows, span(16, 23, 19), "R")
        put(rows, span(17, 22, 20), "r")

    def hurt(self, rows):
        put(rows, both(span(11, 15, 12)), "S")
        put(rows, both([(11, 13), (13, 13), (15, 13)]), "k")
        put(rows, both([(12, 13), (14, 13)]), "S")
        put(rows, span(15, 24, 19), "k")
        put(rows, [(x, 19) for x in range(16, 24, 2)], "w")
        put(rows, span(16, 23, 20), "R")


def official_smoke():
    """4 snímky kouře stoupajícího z cigarety (40x40, průhledné)."""
    sheet = new(SIZE * 4, SIZE)
    rnd = random.Random(1)
    puffs = [(35, 15), (36, 10), (34, 5), (36, 1)]
    for f in range(4):
        img = new(SIZE, SIZE)
        for i, (x, y) in enumerate(puffs):
            yy = y - f * 3  # kouř stoupá o 3 px za snímek
            xx = x + (1 if (f + i) % 2 else 0)
            if yy < 0:
                yy += 18
            col = "G3" if i < 2 else "G2"
            for dx, dy in [(0, 0), (1, 0), (0, 1), (1, 1), (-1, 0)]:
                if rnd.random() < 0.8:
                    px(img, xx + dx, yy + dy, col)
        sheet.alpha_composite(img, (f * SIZE, 0))
    save(sheet, "portraits/official_smoke.png")


# --- Krysa: prašivá, natržené ucho, jizva, slepé oko, zažloutlé zuby -----------

class Rat(Character):
    name = "player"
    body_row = 24
    half = [
        "....................",
        "...kkkk.............",
        "..kffffk............",
        ".kfppppfk...........",
        ".kfpPPpfk...........",
        ".kfpPPpfk....kkkkkkk",
        ".kfppppfkkkkffffffff",
        "..kffffkffffffffffff",
        "...kkkffffffffffffff",
        ".....kffffffffffffff",
        "....kfffflllffffffff",
        "....kffffkkfffffffff",
        "....kfffkewkffffffff",
        "....kffffkkfffffllll",
        ".....kffffffffllllll",
        ".....kFfffffflllllll",
        "..mm..kFffffllllllll",
        "....mmmkFfflllllllll",
        "..mm...kFFllllllllpp",
        "........kFFlllllllPP",
        ".........kFFllllllkl",
        "..........kFFlllllkt",
        "...........kFFllllkt",
        "............kkFFFFkk",
        "........kkbbbkkkkkFF",
        "......kbbbbbbbbbbkFF",
        "....kkbbbbbbbbbbbbkF",
        "...kbbbbbbbbbbbbbbbk",
        "..kbbbbbbbbbbbbbcbbk",
        "..kbbbLbbbbbbbbbcbbk",
        ".kbbbLbbbbbbbbbbcbbk",
        ".kbbbLbbbbbbbbbbbbbk",
        "kbbbbLbbbbbbbbbbbbbk",
        "kbbbbLbbbbbbbbbbbbbk",
        "kbbbbbbbbbbbbbbBBBBk",
        "kbbbbbbbbbbbbbkkkkkk",
        "kbbbbbbbbbbbbbkbbbbb",
        "kbbbbbbbbbbbbbkbbbbb",
        "kbbbbbbbbbbbbbkbbbbb",
        "kbbbbbbbbbbbbbkbbbbb",
    ]
    legend = {
        "k": "K0", "f": "G2", "F": "G1", "l": "G3", "p": "PK", "P": "PD", "e": "K0", "w": "P4",
        "m": "G4", "t": "TY", "b": "B1", "B": "B0", "L": "B2", "c": "G4", "u": "WH", "R": "R0",
        "o": "W0", "x": "G3", "s": "R1",
    }

    def bg(self, img):
        for y in range(SIZE):
            for x in range(SIZE):
                px(img, x, y, "K3" if dither(x, y, 1 - y / SIZE) else "K2")
        rnd = random.Random(3)
        for x0 in range(0, SIZE, 6):
            top = rnd.randrange(14, 28)
            rect(img, x0, top, x0 + 4, SIZE - 1, "K1")
            for wy in range(top + 2, SIZE - 1, 3):
                for wx in range(x0 + 1, x0 + 4, 2):
                    if rnd.random() < 0.35:
                        px(img, wx, wy, rnd.choice(["Y1", "N2", "N1"]))

    def grit(self, rows):
        # natržené pravé ucho
        put(rows, [(34, 1), (35, 1), (34, 2), (35, 2), (35, 3)], ".")
        put(rows, [(33, 2), (34, 3), (36, 2), (36, 3), (35, 4)], "k")
        # prašivé fleky se strupy
        put(rows, [(6, 10), (7, 10), (6, 11)], "p")
        put(rows, [(7, 11)], "s")
        put(rows, [(31, 14), (32, 14), (32, 15)], "p")
        put(rows, [(31, 15)], "s")
        # jizva přes levé oko
        put(rows, [(7, 8), (8, 9), (9, 10), (10, 11), (11, 13), (12, 14)], "P")
        # pravé oko slepé, zakalené
        put(rows, [(29, 12), (30, 12)], "u")
        # vyražený zub
        put(rows, [(20, 22)], "k")
        # ulámané vousy vpravo
        put(rows, [(36, 16), (37, 16), (35, 18), (36, 18)], ".")
        # flekatá a děravá mikina, izolepa
        put(rows, [(8, 30), (9, 30), (9, 31), (27, 33), (28, 33), (24, 29)], "o")
        put(rows, [(31, 36), (32, 36), (31, 37)], "k")
        put(rows, [(x, y) for x in range(12, 16) for y in (34, 35)], "x")

    def blink(self, rows):
        put(rows, [(9, 12), (10, 12), (29, 12), (30, 12)], "k")

    def talk(self, rows):
        put(rows, [(19, 23), (20, 23)], "R")
        put(rows, [(19, 24), (20, 24)], "k")

    def hurt(self, rows):
        put(rows, [(9, 12), (10, 12), (29, 12), (30, 12), (8, 11), (31, 11)], "k")
        put(rows, [(18, 23), (19, 23), (20, 23), (21, 23)], "R")
        put(rows, [(18, 24), (19, 24), (20, 24), (21, 24)], "k")


# --- Šarlatán: sinalá pleť po neštovicích, krvavé oči, shnilé zuby se zlatým ----

class Charlatan(Character):
    name = "charlatan"
    body_row = 22
    half = [
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
    legend = {
        "k": "K0", "h": "K2", "H": "R1", "s": "SK", "S": "SKD", "e": "K0", "m": "W0",
        "y": "Y1", "r": "R1", "R": "R0", "w": "P1", "t": "R2", "c": "PU", "C": "PL",
        "z": "TR", "d": "SKD", "v": "R2", "o": "W1",
    }

    def bg(self, img):
        for y in range(SIZE):
            for x in range(SIZE):
                px(img, x, y, "PU" if dither(x, y, 0.3 + y / 80) else "K2")
        for x0, col in ((2, "N1"), (30, "N2")):
            rect(img, x0, 6, x0 + 6, 14, "K0")
            rect(img, x0 + 1, 7, x0 + 5, 13, col)

    def grit(self, rows):
        # jizvy po neštovicích, propadlé tváře
        put(rows, [(9, 13), (12, 15), (28, 14), (30, 16), (26, 13), (10, 18), (29, 19)], "d")
        put(rows, both([(9, 15), (9, 16), (9, 17)]), "S")
        # krvavé oči s váčky
        put(rows, both([(10, 12)]), "v")
        put(rows, both([(10, 13), (11, 13)]), "S")
        # mastné vlasy zpod klobouku
        put(rows, both([(8, 10), (8, 11)]), "m")
        # shnilý úsměv: hnědé zuby, mezery, jeden zlatý
        for x in range(14, 26):
            rows[17][x] = "z" if x % 2 == 0 else "k"
        put(rows, [(18, 17)], "y")
        put(rows, span(15, 24, 18), "r")
        # strniště
        dither_on(rows, 18, 20, 10, 29, "s", "d")
        # propocený límeček
        put(rows, [(17, 23), (22, 23)], "o")

    def blink(self, rows):
        put(rows, both([(11, 12), (10, 12)]), "S")

    def talk(self, rows):
        put(rows, span(15, 24, 18), "R")
        put(rows, span(16, 23, 19), "r")

    def hurt(self, rows):
        put(rows, both([(11, 12)]), "k")
        put(rows, both([(10, 11), (12, 11)]), "k")
        put(rows, span(15, 24, 18), "R")


# --- Barman: zlomený nos, páska přes oko, vězeňská tetování, krev na zástěře ---

class Barman(Character):
    name = "barman"
    body_row = 22
    half = [
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
    legend = {
        "k": "K0", "s": "S1", "S": "S2", "e": "K0", "b": "W0", "r": "R1", "R": "R0",
        "t": "G4", "a": "P2", "o": "R1", "u": "B1", "n": "R2", "x": "PK", "z": "TY",
    }

    def bg(self, img):
        for y in range(SIZE):
            for x in range(SIZE):
                px(img, x, y, "W0" if x % 7 else "#2a1a10")
        rnd = random.Random(2)
        for x in range(1, SIZE, 4):
            rect(img, x, 4, x + 1, 10, rnd.choice(["O2", "R1", "B1", "Y0"]))
        hline(img, 0, SIZE - 1, 11, "W2")

    def grit(self, rows):
        # páska přes pravé oko a řemínek přes hlavu
        for y in range(8, 11):
            for x in range(25, 31):
                rows[y][x] = "k"
        for i, y in enumerate(range(3, 8)):
            rows[y][26 - i * 3] = "k"
            rows[y][27 - i * 3] = "k"
        # zlomený nos s rudou bulí
        put(rows, [(20, 11), (21, 11)], "n")
        put(rows, [(22, 12), (17, 11)], "S")
        # jizva přes levou tvář, vytetovaná slza
        put(rows, [(8, 10), (9, 11), (10, 12)], "x")
        put(rows, [(11, 11)], "u")
        # pavučina na rameni
        put(rows, [(4, 28), (5, 29), (6, 30), (6, 28), (4, 30), (5, 27), (5, 31), (3, 29), (7, 29)], "u")
        # krev na zástěře
        put(rows, [(24, 30), (25, 30), (25, 31), (13, 34), (14, 35), (27, 37), (16, 31), (23, 36)], "o")
        # žluté zuby s mezerou
        put(rows, [(17, 14), (19, 14), (22, 14)], "z")

    def blink(self, rows):
        put(rows, [(11, 9)], "S")

    def talk(self, rows):
        put(rows, span(16, 23, 14), "R")
        put(rows, span(17, 22, 15), "r")

    def hurt(self, rows):
        put(rows, [(11, 9), (10, 8), (12, 8)], "k")
        put(rows, span(16, 23, 14), "R")


def gen_rib_icon():
    rows = [
        "................",
        "......kkkk......",
        "....kkGGGGkk....",
        "...kGGkkkkGGk...",
        "..kGkk.kk.kkGk..",
        "..kGk..kk..kGk..",
        "..kGGkkkkkkGGk..",
        "..kGkk.kk.kkGk..",
        "..kGk..kk..kGk..",
        "..kGGkkRkkkGGk..",
        "..kGkkRRk.kkGk..",
        "...kGkkRkkkGk...",
        "....kkk.kkkk....",
        ".......kk.......",
        "................",
        "................",
    ]
    save(from_ascii(rows, {"k": "K0", "G": "P3", "R": "R2"}, 16), "icons/card_rib.png")


def main() -> None:
    for cls in (Official, Rat, Charlatan, Barman):
        cls().generate()
    official_smoke()
    gen_rib_icon()


if __name__ == "__main__":
    main()
