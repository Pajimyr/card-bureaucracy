# Balance: proč je hra těžká a co s tím

Datum: 2026-11-19. Čísla jsou ze simulace `tools/balance_sim.py` (10 000 partií na nastavení). Simulátor zrcadlí pravidla z `scripts/main.gd`. Hráč je heuristika (nasazuje karty s nejvyšším ÚT+ŽIV), takže skutečný hráč může být lepší i horší.

## Diagnóza

Při současných číslech vyhraje heuristika jen **asi 10 %** partií:

| Stav | Výhra | Konec kvůli |
|---|---|---|
| Současný stav (balíček 10, úředník nasazuje 3 karty za tah) | 9,6 % | 65 % vyčerpaný balíček, 25 % HP |

Hlavní příčiny:

1. **Vyčerpání balíčku je hlavní zabiják.** Každá mrtvá karta je pryč navždy a balíček má jen 10 karet. Po pár prohraných výměnách přijdeš o polovinu balíčku dřív, než úředníkovi dojde HP.
2. **Úředník nasazuje 3 karty za tah.** Zatímco ty kladeš 3 karty, úředník jich má v každé řadě stejně. Pokrývá tři pruhy, takže tvoje útoky často končí na přední kartě a overflow ti nic nedá.
3. **Úředník má 20 HP a balíček 9 karet**, takže musíš prorazit dlouhou řadu.

Citlivost (jedno číslo najednou od současného stavu):

- balíček hráče 10 → 14: výhra **9,6 % → 37 %**
- úředník nasazuje 3 → 2 karty za tah: výhra **9,6 % → 21 %** (samostatně; v kombinaci s balíčkem 12 je to 66 %)
- HP úředníka 20 → 14: výhra jen na **19,5 %**

Nejsilnější páka je **počet karet úředníka za tah**. Balíček je druhý, HP úředníka je slabá páka.

## Návrh: obtížnost ovlivní balíček a tempo úředníka

Obtížnost zatím mění jen ceny. Navrhuju, aby měnila i sílu úředníka. Cílová výhra pro heuristiku je 45 až 65 %, takže dobrý hráč vyhrává často a slabý sem tam.

| Obtížnost | Balíček hráče | Karty úředníka za tah | Výhra (heuristika) |
|---|---|---|---|
| Úřední hodiny | 12 | 2 | 67 % |
| Pondělí ráno | 11 | 2 | 57 % |
| Pátek 14:55 | 10 | 2 | 47 % |

Úředník má ve všech stupních 20 HP a balíček 9 karet. Současný stav (balíček 10, tempo 3) je těžší než nejtěžší navržený stupeň "Pátek 14:55" (tempo 2), a proto je hra téměř nevyhratelná.

**Stav: schváleno a zapracováno 2026-11-19.** Změny v kódu:
- `GameState.DIFFICULTIES` má nová pole `deck_size` a `enemy_per_turn`, `main.gd` je čte místo pevných konstant.
- Ceny zůstaly beze změny.

## Ruleta místo prohry vyčerpáním (2026-11-20)

Prázdný balíček už neprohrává. Když začne tvůj tah s prázdnou rukou (mimo tutorial), šarlatán nabídne ruletu, nebo můžeš tah nechat propadnout. Prohrává se jen na HP.

Ruleta má 8 polí, 3 výherní: +2 karty, ŽEBRO, +3 karty, RUKA, ŽEBRO, +2 karty, ŽEBRO, ŽEBRO.

- **Karty:** nové náhodné karty do balíčku i do ruky.
- **Žebro:** trvalý debuff Zlomené žebro, max HP −4 (nejvýš 3 žebra, tedy max HP 8). Aktuální HP se ořízne, ale nikdy pod 1. Když už jsou zlomená 3 žebra, bere ruleta 4 aktuální HP (opět ne pod 1).
- **Ruka:** zadarmo přijdeš o ruku (−1 karta za tah). Když už žádnou nemáš, je z toho žebro.

Ruleta hru zlehčuje (s balíčkem 12 by heuristika vyhrála 77 % místo 67 %), proto se balíčky zmenšily o 2:

| Obtížnost | Balíček | Výhra bez rulety (starý balíček) | Výhra s ruletou (nový balíček) |
|---|---|---|---|
| Úřední hodiny | 12 → 10 | 67 % | 62 % |
| Pondělí ráno | 11 → 9 | 57 % | 54 % |
| Pátek 14:55 | 10 → 8 | 47 % | 45 % |

Simulace počítá s heuristikou, která vždycky točí, a s krysou bez debuffů. Žebra a ruce z rulety zůstávají i do dalších případů, takže každé točení má cenu, kterou tabulka nezachytí.

## Další možnosti (nepovinné)

- **Záchrana balíčku:** karta, která zemře, zůstane v balíčku na konci případu s HP 1. Tím se jedna prohra nepromění v trvalou ztrátu. Snižuje to vyčerpání, ale mění to smysl "karta padá a je ztracen". Rozhodnutí je tvoje.
- **Zvýšit počet zahraných karet na tah** pro hráče na 4 pro "Úřední hodiny". Tím se hodně zvedne výhra, ale prostředí se zjednoduší.

## Tutorial

První případ je tutorial (`GameState.tutorial_done`). Má 8 karet hráče, 3 karty úředníka, úředník nasazuje 1 kartu za tah a tři blokující dialogy: úvod, první útok a overflow/postup zadní řady. **Tutorial nejde prohrát:** padlé karty hráče se vracejí do balíčku s plným HP a HP hráče neklesne pod 1. Úředník má jen 3 karty a nic neléčí, takže každá položená karta ho postupně dorazí. Simulace nejhoršího hráče (1 nejslabší karta za tah, náhodný slot) vyhrála všech 3000 partií, nejdéle za 13 kol.

Tutorial má vlastní konstanty `TUT_PLAYER_CARDS`, `TUT_ENEMY_CARDS` a `TUT_ENEMY_CARDS_PER_TURN` v `scripts/main.gd`.

## Kariéra: patra úřadu a výhra (2026-11-26)

Hra měla jen prohru (konec kariéry bez grošů a rukou), vyhrát nešlo. Teď má krysa jasný cíl: vyhrát případ na čtyřech patrech úřadu a porazit ředitele. Prohra zůstává stejná.

| Patro | Úředník | HP | Balíček úředníka | Karty v balíčku úředníka |
|---|---|---|---|---|
| 1 Podatelna | Vrchní podatelna | 16 | 8 | Úředník podatelny, Referent, Revizor |
| 2 Referát | Referent | 20 | 9 | všech 5 původních |
| 3 Odbor | Vedoucí odboru | 20 | 8 | Referent, Revizor, Vedoucí odboru, Kontrolor |
| 4 Ředitelství (boss) | Ředitel | 24 | 6 | Referent, Revizor, Vedoucí, Kontrolor, Tajemník (3/6), Ředitel (5/6) |

HP úředníka je slabá páka (viz výše). Obtížnost pater dělá hlavně síla karet v jeho balíčku a velikost balíčku. Boss má malý balíček, ale silné karty.

Výhra jednoho případu pro heuristiku (Pondělí ráno, balíček 9, krysa bez efektů):

| Patro | Výhra |
|---|---|
| 1 | 93 % |
| 2 | 54 % |
| 3 | 39 % |
| 4 (boss) | 22 % |

Vliv zboží z baru na bosse (každé samostatně): nic 20 %, úplatek 32 %, kafe 27 %, padělané razítko 41 %, vesta 24 %. Razítko je nejsilnější, proto stojí 22 grošů a dají se mít nejvýš tři.

Celá kariéra (simulace `python3 tools/balance_sim.py career`, 5000 her na řádek). Strategie s nákupy: drží si rezervu na další kolo, kupuje razítka, vestu, mast na žebra a před bossem úplatek s kafem. Když nemá na kolo, prodá ruku.

| Obtížnost | Výhra bez nákupů | Výhra s nákupy | Průměrně případů do výhry |
|---|---|---|---|
| Úřední hodiny | 57 % | 98 % | 4,1 |
| Pondělí ráno | 33 % | 92 % | 4,3 |
| Pátek 14:55 | 9 % | 32 % | 4,8 |

Hra se tedy dá vyhrát a bar má smysl: kdo nakupuje, vyhrává mnohem častěji. Pátek 14:55 zůstává těžký schválně.
