# Plán: menu, město, ekonomie a černý trh

Stav: rozpracováno. Pořadí kroků je dole, zaškrtávej průběžně.

## Tón a téma
- **Hráč je krysa.** Není to čestný občan, ale někdo, kdo se proplétá systémem a obchoduje v šedé zóně. Texty, UI i obchodníci to mají odrážet (drzé, lstivé, pragmatické).
- Město: nahoře úřady a věže, dole slumy. Hráč patří dolů.

## 1. Hlavní menu
- [ ] Scéna `menu.tscn` jako nový vstup (místo `main.tscn`).
- [ ] Tlačítko **Hrát** → obrazovka výběru obtížnosti.
- [ ] Obrazovka obtížnosti: tři volby (zatím bez efektu). Výběr se ukládá do globálního stavu.
- [ ] Potvrzení obtížnosti spustí hru (`main.tscn`).
- [ ] Tlačítko **Zpět** na každé podobrazovce.

## 2. Konec případu → město
- [ ] Po každém konci případu (výhra i prohra) přechod do města, až po death screenu (ZAMÍTNUTO / SCHVÁLENO).
- [ ] Scéna `city.tscn`: pixel art slumů s bezdomovci (asset přes `tools/gen_assets.py`).
- [ ] Klikatelné oblasti s hoverem (světlejší obrys nebo rámeček).
  - [ ] **Úřad / soud**: pixel art budovy, hover, klik → opakování kola (viz bod 3).
  - [ ] **Bar v slumech**: pixel art, hover, klik → černý trh (viz bod 5).

## 3. Úřad / soud: opakování kola
- [ ] Sekce pod informacemi (groše, debuffy), ne tlačítko. Pixel art úřadu nebo soudu, hover zvýrazní.
- [ ] Opakování kola stojí **10 grošů**. První kolo zdarma.
- [ ] Když hráč nemá 10 grošů, sekce je zašedlá a klik nic nedělá. Hráč se musí dostat do baru.

## 4. Ekonomika a stav hráče
- [ ] Start: **50 grošů**, první kolo zdarma, každé další opakování 10.
- [ ] Výhra v případu: **+20 grošů**.
- [ ] Peníze a debuffy/buffy se drží mezi scénami (autoload `GameState`).
- [ ] Pravý panel města: groše, aktivní debuffy a buffy.

## 5. Černý trh (bar v slumech)
- [ ] Vstup: prohra bez 10 grošů automaticky vede do baru. Hráč tam může prodávat, nebo nakupovat.
- [ ] Pixel art baru, barman. Hráč řekne heslo **„Jdu sem pro Honzu“**, barman ho vezme za závěs, kde je obchod.
- [ ] Obchod: prodej vlastních karet (groše za kartu, cena je debuff), nákup buffů a debuffů za groše.
- [ ] Heslo: zatím nevím, jestli je to napsaný text, nebo volba v dialogu. Viz otevřené otázky.

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
