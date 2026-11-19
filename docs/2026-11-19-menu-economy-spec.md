# Zadání pro Opuse: menu, tutoriál, město, groše, černý trh

Datum: 2026-11-19
Stav: schváleno k implementaci. Otevřené věci nejsou, rozhodnutí jsou níže.

## Tón
- **Hráč je krysa.** Drzý, pragmatický obchodník v šedé zóně, ne čestný občan.
- Krysa má být vidět v grafice: hráčův portrét (`portraits/player.png`) bude krysa, ne člověk v kapuci.
- Město: nahoře úřady a věže, dole slumy. Hráč patří dolů.

## 1. Hlavní menu
- Nová scéna `menu.tscn` jako vstup hry (místo `main.tscn`).
- Tlačítko **Hrát** → obrazovka výběru obtížnosti.
- Obtížnost: tři volby. Zatím bez efektu v kódu, ale **ovlivní ceny v baru a cenu dalšího kola** (viz bod 4, 5). Výběr se ukládá do autoloadu `GameState`.
- Potvrzení obtížnosti spustí tutoriál (bod 2).
- Tlačítko **Zpět** na každé podobrazovce.

## 2. Tutoriál a dialogy
- Při prvním spuštění (po obtížnosti) se hráči ukáže dialog se **šarlatánem**.
- Šarlatán hráči řekne heslo **„Jdu sem pro Honzu“** a naznačí, že tohle heslo otevře cestu do slumů a do baru.
- Potřeba: jednoduchý systém dialogů (text, pokračovat klikem, volitelně volba). Ukládat, že tutoriál proběhl.
- Dialogy budou víc, systém navrhni tak, aby šel rozšířit.

## 3. Město
- Scéna `city.tscn`: pixel art slumů s bezdomovci (nový asset přes `tools/gen_assets.py`).
- Dvě klikatelné oblasti s hoverem (světlejší obrys nebo rámeček):
  - **Úřad / soud**: pixel art budovy. Klik → opakování kola.
  - **Bar**: pixel art baru v slumech. Klik → černý trh.
- Pravý panel města: groše, aktivní debuffy a buffy (buffy zatím prázdné, místo připravit).
- Debuff **Bez ruky** se zobrazuje jako karta (rub nebo speciální karta s ikonou ruky), ne jen text.

## 4. Úřad / soud: opakování kola
- Stojí **10 grošů**. První kolo zdarma.
- Cena se čte z `GameState`, aby ji obtížnost mohla měnit.
- Bez 10 grošů je sekce zašedlá a klik nic nedělá.

## 5. Ekonomika
- Start: **50 grošů**.
- Výhra v případu: **+20 grošů**.
- Prohra bez 10 grošů: hra po death screenu **automaticky přesměruje do baru** a nabídne prodej.
- Groše a debuffy/buffy se drží mezi scénami (`GameState`).
- Obtížnost ovlivňuje: cenu opakování kola a ceny v baru. Hodnoty navrhni jako konstanty, ať je jde snadno ladit.

## 6. Černý trh (bar)
- Barman. Hráč řekne heslo (z tutoriálu) a barman ho vezme za závěs do zadní místnosti.
- V zadní místnosti obchod:
  - **Prodej** vlastní karty za groše. Prodaná karta se vymaže z hry a hráč dostane debuff.
  - **Nákup** buffů a debuffů za groše.
- Při prodeji **ruky** se karta vybírá **náhodně** z ruky hráče.
- Ceny ovlivňuje obtížnost.

## 7. Debuffy a buffy

**Bez ruky** (debuff, zatím jediný)
- Každý kus = o jednu kartu méně za tah.
- Maximálně **2 kusy**. Počet karet za tah = `MAX_CARDS_PER_TURN` (3) mínus počet kusů, minimum 1.
- Zobrazuje se jako karta v pravém panelu města.
- Prodej ruky: vymaže náhodnou kartu z ruky, přidá jeden kus „Bez ruky“. Při dvou kusech je prodej ruky nedostupný.

**Buffy a další debuffy**
- Zatím nedefinované. Systém musí umět obojí (kladné i záporné efekty) a zobrazovat je stejně jako Bez ruky.

## Technické poznámky
- Konstanta `MAX_CARDS_PER_TURN` a energetické žetony v `scripts/main.gd` se musí napojit na počet karet po debuffu.
- Balíček a ruka zůstávají v `main.gd`. Ekonomika a debuffy jdou do autoloadu `GameState`, aby přežily přechod scén.
- Všechny nové obrazovky (menu, obtížnost, dialog, město, bar) držet ve stejné paletě a stylu jako existující UI (`assets/ui/`).
- Pixel art přes `tools/gen_assets.py`, žádné ruční obrázky.
