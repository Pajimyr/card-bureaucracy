# Card Bureaucracy: design dokument

Původní koncept z bloku 1 je v [game-concept.md](game-concept.md). Tento dokument popisuje hru tak, jak je opravdu udělaná (stav 2026-11-26), a u každé části říká, kde je v kódu.

## 1. Shrnutí

| | |
|---|---|
| Žánr | 2D tahová karetní hra, krátká kampaň (roguelite prvky) |
| Engine | Godot 4.7, GDScript |
| Platforma | PC (Linux, Windows, macOS), ovládání myší |
| Délka hry | 15 až 30 minut na jednu kariéru |
| Hráč | krysa ze slumů, která se chce dostat úřadem až nahoru |
| Tón | černý humor, česká byrokracie, cyberpunkové město (nahoře věže, dole slumy) |

**Pitch:** Úřad je dungeon, úředníci jsou monstra a formuláře jsou zbraně. Kdo nemá na poplatek, prodá v baru vlastní ruku.

## 2. Cíl hry, výhra a prohra

**Výhra:** vyhrát případ na každém ze čtyř pater úřadu. Čtvrté patro je ředitel (boss). Po jeho porážce dopadne razítko **POVÝŠEN**, běží závěrečný dialog a obrazovka **KARIÉRA DOKONČENA** se statistikami (počet případů, výhry/prohry, groše, žebra, prodané ruce).

**Prohra případu:** HP krysy klesne na 0. Krysa jde do města (nebo rovnou do baru, když nemá na další pokus) a patro musí zkusit znovu za poplatek.

**Prohra celé hry:** krysa nemá groše na poplatek za další případ a nemá už ani ruku, kterou by prodala. Dopadne razítko **KONEC KARIÉRY** a hra se vrátí do menu.

Kód: `GameState.career_won()`, `GameState.is_stuck()`, `GameState.finish_case()` v `scripts/game_state.gd`. Konec hry: `scripts/ending.gd`.

## 3. Herní smyčka

```
menu → obtížnost → šarlatán (heslo do baru) → zkouška (tutoriál)
  ↓
město ──► úřad: zaplať poplatek ──► případ na aktuálním patře
  ▲                                     │
  │          výhra: +20 grošů, patro +1 ┤
  │          prohra: patro zůstává      │
  └──── bar (obchod) ◄──────────────────┘
                    ...po 4. patře → KARIÉRA DOKONČENA
```

1. **Případ** je jeden souboj s úředníkem daného patra.
2. **Město** ukazuje groše, efekty na kryse a kariéru (žetony pater v záhlaví).
3. **Úřad** spustí další případ za poplatek (podle obtížnosti 8, 10 nebo 15 grošů).
4. **Bar** je černý trh: prodej rukou a nákup zboží.

## 4. Souboj (případ)

Kód: `scripts/main.gd`.

- Každá strana má **3 pruhy × 2 řady** (přední a zadní). Zadní slot jde obsadit, jen když je přední obsazený.
- Karta má **ÚT** (útok) a **ŽIV** (životy). Karta na 0 ŽIV padá a je pro tento případ ztracená.
- **Tah hráče:** zahraje až 3 karty (méně za každou prodanou ruku, víc s kafem), pak klikne na POTVRDIT TAH.
- **Tah úředníka:** nasadí 2 karty, pak se počítá souboj.
- **Souboj:** každá přední karta udeří protější přední kartu ve svém pruhu. Přebytek útoku, který kartu nezabil, propadne na zadní kartu za ní, a když tam žádná není, jde přímo do HP soupeře. Prázdný pruh = zásah přímo do HP. Když přední karta padne, zadní postoupí a hned útočí.
- **Prázdná ruka:** šarlatán nabídne **ruletu** (8 polí, 3 výherní). Výhra = nové karty, prohra = zlomené žebro (−4 max HP, nejvýš 3) nebo ztráta ruky. Ruletu jde odmítnout a ztratit tah.
- Hráč má 20 HP (méně se zlomenými žebry, víc s vestou). Balíček hráče je náhodný a má podle obtížnosti 10, 9 nebo 8 karet.

### Karty hráče

| Karta | ÚT | ŽIV |
|---|---|---|
| Formulář B-7 | 2 | 3 |
| Razítko | 3 | 2 |
| Žádost o žádost | 1 | 5 |
| Úřední lhůta | 4 | 2 |
| Kopie kopie | 1 | 2 |
| Nahlédnutí do spisu | 1 | 4 |
| Podpis pod tlakem | 5 | 4 |
| Ověřená kopie | 2 | 4 |
| Stížnost | 2 | 3 |
| Výpis z rejstříku | 3 | 3 |
| Padělané razítko (jen z baru) | 4 | 4 |

### Karty úředníků

| Karta | ÚT | ŽIV |
|---|---|---|
| Úředník podatelny | 1 | 3 |
| Referent | 2 | 4 |
| Revizor | 3 | 3 |
| Vedoucí odboru | 4 | 4 |
| Kontrolor | 3 | 5 |
| Tajemník | 3 | 6 |
| Ředitel | 5 | 6 |

## 5. Patra úřadu (progrese)

Kód: `GameState.RANKS`.

| Patro | Případ | Úředník | HP | Balíček | Poznámka |
|---|---|---|---|---|---|
| Zkouška | Vyplň formulář | Vrátný | 20 | 3 karty | tutoriál, nejde prohrát, nepočítá se do pater |
| 1 Podatelna | Potvrzení totožnosti | Vrchní podatelna | 16 | 8 | slabé karty, rozehřátí |
| 2 Referát | Trvalý pobyt v kanálu | Referent | 20 | 9 | všechny základní karty |
| 3 Odbor | Díra ve zdi | Vedoucí odboru | 20 | 8 | jen silnější karty |
| 4 Ředitelství | Žádost o povýšení | Ředitel (boss) | 24 | 6 | malý balíček, nejsilnější karty |

Obtížnost pater roste hlavně silou karet v balíčku úředníka. HP je podle simulace slabá páka (viz [balance.md](balance.md)).

## 6. Ekonomika

Kód: `GameState.DIFFICULTIES`, `GameState.ITEMS`.

- Start: **50 grošů**. Výhra případu: **+20**. Zkouška je zdarma.
- Poplatek za další případ: 8 / 10 / 15 (Úřední hodiny / Pondělí ráno / Pátek 14:55).
- Ceny zboží v baru se násobí 0,8 / 1,0 / 1,3 podle obtížnosti.

| Zboží | Cena (Pondělí ráno) | Typ | Efekt | Limit |
|---|---|---|---|---|
| Prodej ruky | +20 | debuff | −1 karta za tah | 2 ruce |
| Protéza | 40 | buff | vrátí kartu za tah | podle prodaných rukou |
| Šarlatánova mast | 20 | služba | zahojí jedno zlomené žebro | – |
| Vatovaná vesta | 25 | trvalý buff | +4 max HP | 2 |
| Padělané razítko | 22 | trvalý buff | karta 4/4 navíc v každém případu | 3 |
| Úplatek | 12 | na 1 případ | úředník začne s −6 HP | 1 |
| Kafe z automatu | 15 | na 1 případ | +1 karta za tah | 1 |

Jednorázové zboží (úplatek, kafe) se spotřebuje na začátku dalšího případu. Trvalé efekty a deformity (žebra, ruce, protézy) zůstávají celou hru a jsou vidět ve městě.

## 7. Obtížnost

| | Úřední hodiny | Pondělí ráno | Pátek 14:55 |
|---|---|---|---|
| Balíček hráče | 10 | 9 | 8 |
| Karty úředníka za tah | 2 | 2 | 2 |
| Poplatek za případ | 8 | 10 | 15 |
| Výkup ruky / protéza | 25 / 30 | 20 / 40 | 15 / 55 |
| Ceny zboží | ×0,8 | ×1,0 | ×1,3 |
| Výhra kariéry (simulace, s nákupy) | 98 % | 92 % | 32 % |

## 8. Obrazovky

| Scéna | Soubor | Obsah |
|---|---|---|
| Menu | `scenes/menu.tscn` | Hrát, výběr obtížnosti (s cílem hry), úvodní dialog se šarlatánem |
| Případ | `scenes/main.tscn` | souboj, protokol, ruleta, razítko SCHVÁLENO / ZAMÍTNUTO / POVÝŠEN |
| Město | `scenes/city.tscn` | slumy s barem, stav krysy, kariéra v záhlaví, úřad |
| Bar | `scenes/bar.tscn` | barman, heslo, Honzův obchod (mřížka 7 nabídek) |
| Konec | `scenes/ending.tscn` | závěrečný dialog, KARIÉRA DOKONČENA, statistiky |

## 9. Grafika a zvuk

- Pixel art 640x360 zvětšený 2x. Všechno kreslí skripty v `tools/` (Python + Pillow), ručně se nic nekreslí. Díky tomu jde grafiku kdykoli přegenerovat a paleta je na jednom místě.
- Animované portréty (dýchání, mrkání, mluvení, cuknutí při zásahu), plamen v sudu, blikající neon baru.
- Zvuk zatím není.

## 10. Architektura

- `GameState` (autoload) drží všechno, co přežívá mezi scénami: groše, patro, efekty, obtížnost. Má jednotné rozhraní pro obchod (`item_price`, `item_problem`, `buy_item`), takže bar jen kreslí a nic nepočítá.
- `main.gd` drží jen stav jednoho případu (balíčky, stůl, HP). Na začátku si z `GameState` vezme patro a spotřebuje jednorázové zboží.
- `UiKit` je sdílená paleta, font a stavební bloky UI (panely, tlačítka, karta efektu, razítko přes obrazovku).
- Balance se neladí odhadem, ale simulací (`tools/balance_sim.py`), která zrcadlí pravidla souboje.

## 11. Co dál (mimo rozsah odevzdání)

- Zvuky a hudba.
- Speciální schopnosti karet (koncept je zmiňuje, zatím nejsou).
- Vlastní portrét pro každého úředníka (teď všichni sdílí jeden portrét, liší se ikonou karty).
- Ukládání rozehrané hry.
