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

Úředník má všude 20 HP a balíček 9 karet. Současný stav (10 a 3) je v tabulce jako "Pátek" s tempem 3, a to je příliš těžké.

Konkrétní změny v kódu, až to schválíš:
- `PLAYER_DECK_SIZE` nahradit hodnotou z `GameState.DIFFICULTIES` (nové pole `deck_size`).
- `ENEMY_CARDS_PER_TURN` nahradit hodnotou z `GameState.DIFFICULTIES` (nové pole `enemy_per_turn`).
- Ceny zůstávají, jen se přepočítají po změně.

## Další možnosti (nepovinné)

- **Záchrana balíčku:** karta, která zemře, zůstane v balíčku na konci případu s HP 1. Tím se jedna prohra nepromění v trvalou ztrátu. Snižuje to vyčerpání, ale mění to smysl "karta padá a je ztracen". Rozhodnutí je tvoje.
- **Zvýšit počet zahraných karet na tah** pro hráče na 4 pro "Úřední hodiny". Tím se hodně zvedne výhra, ale prostředí se zjednoduší.
- **Ukončení tahu bez nasazení:** dnes můžeš potvrdit tah i s prázdnou rukou. To je v pořádku, ale pokud úředník všechno zablokuje, nemáš co dělat. Tohle zatím neřeším.

## Tutorial

První případ je tutorial (`GameState.tutorial_done`). Má 8 karet hráče, 3 karty úředníka, úředník nasazuje 1 kartu za tah a tři blokující dialogy: úvod, první útok a overflow/postup zadní řady. Simulace na těchto číslech vyhrává v 88 % (heuristika), takže tutorial je spíš prostor k učení než zkouška.

Tutorial má vlastní konstanty `TUT_PLAYER_CARDS`, `TUT_ENEMY_CARDS` a `TUT_ENEMY_CARDS_PER_TURN` v `scripts/main.gd`.
