# Podklady k obhajobě

Obhajoba je individuální. Tohle je tahák, co si projít, abys uměl vysvětlit **svůj** projekt, včetně částí, které psala AI. Ke každé otázce si zkus odpovědět nahlas bez dívání do kódu, pak si to ověř v uvedeném souboru.

## 1. Hra za 30 sekund

Krysa ze slumů se probíjí úřadem. Čtyři patra, na každém souboj karet s úředníkem. Výhra = porazit ředitele na 4. patře. Prohra = nemáš peníze na další pokus a už nemáš ani ruku na prodej. Mezi případy se v baru nakupuje zboží (vesta, razítko, úplatek…) a prodávají se ruce.

## 2. Architektura (nakresli si to)

```
           ┌────────────── GameState (autoload) ───────────────┐
           │ groše, patro (rank), efekty, obtížnost, obchod    │
           └──▲──────────▲──────────▲──────────▲───────────▲───┘
              │          │          │          │           │
           menu.gd    main.gd    city.gd    bar.gd     ending.gd
          (obtížnost) (souboj)  (stav, úřad) (obchod)  (výhra)
                         │
                   roulette.gd, dialog_box.gd, character_portrait.gd
                   UiKit (ui_kit.gd): paleta, font, panely, razítko
```

- **Proč autoload?** Scény se při přechodu ničí. Co má přežít (groše, efekty, patro), musí žít mimo ně. `GameState` je v `project.godot` pod `[autoload]`.
- **Proč je UI v kódu, ne v editoru?** `.tscn` jsou jen kořenový uzel se skriptem. Výhoda: všechno je v GDScriptu, dobře se to verzuje a mění. Nevýhoda: nevidíš layout v editoru.
- **Proč grafika z Pythonu?** Jednotná paleta, jde kdykoli přegenerovat, nikdo z týmu nemusí kreslit. `python3 tools/gen_assets.py`.

## 3. Otázky, které můžou padnout

**Jak funguje souboj?** (`main.gd`, `_resolve_combat`, `_attack_pass`, `_overflow`, `_cleanup_dead`)
Přední karty v pruhu se bijí. Přebytek útoku propadne na zadní kartu, jinak do HP. Pak úklid: mrtvé pryč, zadní postoupí a v dalším průchodu útočí jen ty postoupivší. Max 20 průchodů jako pojistka proti nekonečné smyčce.

**Kde se rozhoduje o výhře hry?** (`game_state.gd`)
`finish_case(won, was_tutorial)` zvedne `rank`. `career_won()` vrací `rank >= RANKS.size()`. V `main.gd` `_on_case_finished` pak přepne na `scenes/ending.tscn`.

**A o prohře?**
`is_stuck()`: nemá na `round_cost()` a `can_sell_hand()` je false. Kontroluje se při vstupu do města a při odchodu z baru.

**Jak přidám nové zboží do baru?**
1. Záznam do `GameState.ITEMS` (cena, limit, popis) a `EFFECTS` (ikona, typ, případně `once`).
2. Id do `SHOP_ORDER`.
3. Efekt zapojit tam, kde se projeví (např. `player_max_hp()` nebo start případu v `main.gd::_ready`).
4. Ikonu nakreslit do `CARD_ICONS` v `tools/gen_assets.py`.
Bar se překreslí sám, protože je postavený z dat.

**Jak víte, že se hra dá vyhrát?**
Simulace `tools/balance_sim.py` odehraje tisíce celých kariér s jednoduchou strategií. Pondělí ráno: 33 % bez nákupů, 92 % s nákupy. Tabulky v `docs/balance.md`. Simulátor je heuristika, ne člověk, takže je to odhad.

**Proč má boss méně HP než by člověk čekal, ale je nejtěžší?**
Simulace ukázala, že HP je slabá páka. Rozhoduje síla a počet karet v balíčku úředníka. Ředitel má malý balíček (6), ale karty 5/6 a 3/6.

**Jak testujete?**
`godot --headless --path . -s tests/test_runner.gd`: 89 kontrol (kariéra, obchod, efekty, souboj, start případu). Plus ruční scénář `docs/testovaci-scenar.md` a snímky obrazovky přes `tools/screenshot.gd`.

**Co je tutoriál a proč nejde prohrát?**
První případ: menší balíčky, úředník 1 kartu za tah, padlé karty se vracejí, HP neklesne pod 1. Nepočítá se do pater.

**Co dělá ruleta?**
Při prázdné ruce. 8 polí, 3 dávají karty, zbytek zlomené žebro (−4 max HP) nebo ruku. Místo prohry vyčerpáním balíčku.

**K čemu je `.uid` soubor u skriptů?**
Godot 4 tím drží stabilní identifikátor zdroje, aby odkazy přežily přejmenování. Patří do gitu.

**Proč aplikace spadne po čerstvém klonu bez importu?**
`.godot/` (cache tříd s `class_name` a importovaná grafika) je v `.gitignore`. Proto je v README krok `--import`.

## 4. Na co se připravit kriticky

- Umět říct, **co jsi dělal ty** a co AI. Projdi si `git log` a svůj deník selhání AI.
- Umět vysvětlit aspoň jednu funkci řádek po řádku (doporučení: `GameState.buy_item` nebo `main.gd::_overflow`).
- Vědět slabiny: všichni úředníci sdílí jeden portrét, chybí zvuk, testy souboje jsou jen dva scénáře, simulátor hraje jednoduchou strategii.
