# Plán: menu, město, ekonomie a černý trh

Stav: hotovo (2026-11-19, zaškrtnuto zpětně 2026-11-26). Přesné zadání a odchylky jsou v `docs/2026-11-19-menu-economy-spec.md`, ceny podle obtížnosti v `scripts/game_state.gd`.

## Tón a téma
- **Hráč je krysa.** Není to čestný občan, ale někdo, kdo se proplétá systémem a obchoduje v šedé zóně. Texty, UI i obchodníci to mají odrážet (drzé, lstivé, pragmatické).
- Město: nahoře úřady a věže, dole slumy. Hráč patří dolů.

## 1. Hlavní menu
- [x] Scéna `menu.tscn` jako nový vstup (místo `main.tscn`).
- [x] Tlačítko **Hrát** → obrazovka výběru obtížnosti.
- [x] Obrazovka obtížnosti: tři volby (zatím bez efektu). Výběr se ukládá do globálního stavu.
- [x] Potvrzení obtížnosti spustí hru (`main.tscn`).
- [x] Tlačítko **Zpět** na každé podobrazovce.

## 2. Konec případu → město
- [x] Po každém konci případu (výhra i prohra) přechod do města, až po death screenu (ZAMÍTNUTO / SCHVÁLENO).
- [x] Scéna `city.tscn`: pixel art slumů s bezdomovci (asset přes `tools/gen_assets.py`).
- [x] Klikatelné oblasti s hoverem (světlejší obrys nebo rámeček).
  - [x] **Úřad / soud**: pixel art budovy, hover, klik → opakování kola (viz bod 3).
  - [x] **Bar v slumech**: pixel art, hover, klik → černý trh (viz bod 5).

## 3. Úřad / soud: opakování kola
- [x] Sekce pod informacemi (groše, debuffy), ne tlačítko. Pixel art úřadu nebo soudu, hover zvýrazní.
- [x] Opakování kola stojí **10 grošů**. První kolo zdarma.
- [x] Když hráč nemá 10 grošů, sekce je zašedlá a klik nic nedělá. Hráč se musí dostat do baru.

## 4. Ekonomika a stav hráče
- [x] Start: **50 grošů**, první kolo zdarma, každé další opakování 10.
- [x] Výhra v případu: **+20 grošů**.
- [x] Peníze a debuffy/buffy se drží mezi scénami (autoload `GameState`).
- [x] Pravý panel města: groše, aktivní debuffy a buffy.

## 5. Černý trh (bar v slumech)
- [x] Vstup: prohra bez 10 grošů automaticky vede do baru. Hráč tam může prodávat, nebo nakupovat.
- [x] Pixel art baru, barman. Hráč řekne heslo **„Jdu sem pro Honzu“**, barman ho vezme za závěs, kde je obchod.
- [x] Obchod: prodej vlastních karet (groše za kartu, cena je debuff), nákup buffů a debuffů za groše.
- [x] Heslo: zatím nevím, jestli je to napsaný text, nebo volba v dialogu. Viz otevřené otázky.

## Debuffy a buffy

**Bez ruky** (debuff)
- Každý kus = o jednu kartu méně za tah.
- Maximálně 2 kusy. Hráč tak zahraje nejvýše jednu kartu za tah.
- Prodej ruky: karta se vymaže z hry a přidá se jeden kus „Bez ruky“.

**Buffy a další debuffy**
- Zatím nedefinované, přidáme do seznamu. Měly by být vidět v pravém panelu města i v obchodě.

## Otevřené otázky
- Je heslo „Jdu sem pro Honzu“ napsaný text v terminálu, nebo volba z dialogu?
- Prodej ruky: vybírá hráč, kterou kartu prodá, nebo se bere náhodná?
- Co přesně dělají buffy? Chceš jich pár hned, nebo až po prvním testování?
- Obtížnost: má ovlivnit ceny v baru, nebo počet protivníků?
- Je krysa jen tón, nebo chceš, aby byla vidět v grafice (např. hráčova postava v portrétu)?
