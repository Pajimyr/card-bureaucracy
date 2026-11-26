# Ruční testovací scénář

Projdi před každým odevzdáním. Automatické testy (`godot --headless --path . -s tests/test_runner.gd`) kontrolují logiku. Tento scénář kontroluje to, co automat nevidí: obrazovky, klikání a celý průchod hrou.

Ke každému kroku zapiš ✅ / ❌ a u chyby krátký popis. Tabulka na konci slouží jako záznam běhu.

## Příprava

| # | Krok | Očekávaný výsledek |
|---|---|---|
| P1 | Čerstvý `git clone`, pak `godot --headless --path . --import` | doběhne bez chyb |
| P2 | `godot --headless --path . -s tests/test_runner.gd` | `… prošlo, 0 selhalo` |
| P3 | `godot --path .` | otevře se menu s krysou a nápisem CARD BUREAUCRACY |

## A. Menu a tutoriál

| # | Krok | Očekávaný výsledek |
|---|---|---|
| A1 | Klikni HRÁT | tři okna obtížnosti s cenami a řádek „Cíl: vyhraj případ na všech 4 patrech…“ |
| A2 | ZPĚT | návrat na hlavní menu |
| A3 | Vyber Pondělí ráno | dialog se šarlatánem, zmíní čtyři patra a heslo „Jdu sem pro Honzu“ |
| A4 | Odklikej dialog (myš i Enter) | text se dopíše, pak další řádek; volba jde vybrat kliknutím |
| A5 | Zkouška: přetáhni kartu na přední slot | karta přiletí do slotu, žeton zahraných karet zešedne |
| A6 | Zkus položit kartu do zadní řady bez přední | nejde, protokol napíše důvod |
| A7 | Zahraj 4. kartu v jednom tahu | nejde, protokol: „Na tah můžeš zahrát jen 3 karty.“ |
| A8 | Klikni kartu a pak slot (bez tažení) | karta se položí stejně jako tažením |
| A9 | Dohraj zkoušku | razítko SCHVÁLENO, „Zkouška složena. +20 grošů.“ |

## B. Město

| # | Krok | Očekávaný výsledek |
|---|---|---|
| B1 | Po zkoušce | město: 70 grošů, záhlaví „KARIÉRA ○○○○ Patro 1/4: Podatelna“ |
| B2 | Najeď myší na bar | bar se rozsvítí, popisek se změní |
| B3 | Úřad dole vpravo | „ÚŘAD · PATRO 1: PODATELNA“, poplatek 10 grošů |

## C. Bar a obchod

| # | Krok | Očekávaný výsledek |
|---|---|---|
| C1 | Klikni na bar, vyber „Jdu sem pro Honzu.“ | barman odhrne závěs, objeví se obchod se 7 nabídkami |
| C2 | Protéza a mast bez prodané ruky / žebra | tlačítko NEPOTŘEBUJEŠ, nejde kliknout |
| C3 | Kup úplatek | groše −12, zelená hláška, tlačítko se změní na MÁŠ DOST |
| C4 | Kup kafe | groše −15 |
| C5 | Prodej ruku | groše +20, otřes obrazovky, červená hláška o levé/pravé ruce |
| C6 | Kup protézu | groše −40 (jestli na ni máš), hláška „… protéza sedí“ |
| C7 | Nakupuj, dokud nedojdou groše | zbylé zboží ukazuje NEMÁŠ NA TO |
| C8 | ODEJÍT | návrat do města, efekty jsou vidět v panelu DEBUFFY A BUFFY |

## D. Případ se zbožím

| # | Krok | Očekávaný výsledek |
|---|---|---|
| D1 | Úřad (s koupeným úplatkem a kafem) | protokol: „Úplatek zabral: úředník začíná na 10 HP.“ a „Kafe z automatu…“ |
| D2 | Žetony zahraných karet | 4 žetony místo 3 |
| D3 | Záhlaví případu | „PATRO 1/4 · PODATELNA“, úředník „VRCHNÍ PODATELNA“ |
| D4 | Vrať se po případu do města | úplatek a kafe v efektech už nejsou |
| D5 | Kup padělané razítko a jdi na úřad | balíček má o 1 kartu víc, karta Padělané razítko 4/4 se dá zahrát |

## E. Ruleta

| # | Krok | Očekávaný výsledek |
|---|---|---|
| E1 | Hraj, dokud nezačne tah s prázdnou rukou | šarlatán nabídne ruletu nebo ztrátu tahu |
| E2 | Zatoč | kolo se roztočí, výsledek: karty, žebro nebo ruka |
| E3 | Žebro | max HP −4, ve městě „Zlomené žebro“ |
| E4 | Ztratit tah | tah propadne, hraje úředník |

## F. Prohra

| # | Krok | Očekávaný výsledek |
|---|---|---|
| F1 | Prohraj případ (HP na 0) | razítko ZAMÍTNUTO, „Patro musíš zkusit znova.“ |
| F2 | Město po prohře | patro se nezměnilo, úřad píše „ZNOVU PATRO …“ |
| F3 | Prohra bez peněz na poplatek | rovnou bar, barman: „Bez grošů tě tam znova nepustí…“ |
| F4 | Bez peněz a bez rukou (snímek: `setup=hands scene=city`) | razítko KONEC KARIÉRY, tlačítko HLAVNÍ MENU |

## G. Výhra

| # | Krok | Očekávaný výsledek |
|---|---|---|
| G1 | Vyhraj případ na patře 1 | razítko SCHVÁLENO, ve městě jeden zlatý žeton, „Patro 2/4: Referát“ |
| G2 | Dojdi na patro 4 | záhlaví případu červeně „PATRO 4/4 · ŘEDITELSTVÍ“, úředník „ŘEDITEL“, podtitul „Boss“ |
| G3 | Poraz ředitele | zlaté razítko POVÝŠEN, „Ředitel padl. Kancelář nahoře je tvoje.“ |
| G4 | POKRAČOVAT | závěrečný dialog, pak KARIÉRA DOKONČENA se statistikami |
| G5 | HLAVNÍ MENU, nová hra | groše 50, patro 1, žádné efekty |

Na rychlé ověření bez hraní celé kariéry jde použít snímky (viz hlavička `tools/screenshot.gd`):

```bash
godot --path . -s tools/screenshot.gd -- out=/tmp/boss.png scene=main setup=boss
godot --path . -s tools/screenshot.gd -- out=/tmp/win.png scene=main setup=boss action=end_win
godot --path . -s tools/screenshot.gd -- out=/tmp/end.png scene=ending setup=won action=results
godot --path . -s tools/screenshot.gd -- out=/tmp/shop.png scene=bar setup=shop action=honza after=80
```

## Záznam běhů

| Datum | Kdo | Commit | Výsledek | Poznámka |
|---|---|---|---|---|
| 2026-11-26 | Claude (automaticky) | – | P1–P3 ✅, snímky D/F/G ✅ | testy 89/0; ručně proklikat A–G zatím nikdo |
