# Deník selhání AI: Pajimyr

> **KONCEPT, PŘEPIŠ VLASTNÍMI SLOVY.** Tyhle případy sepsala AI podle toho, co je doložené v repozitáři (commity, `docs/balance.md`, `docs/2026-11-19-menu-economy-spec.md`) a co se stalo v sezení 2026-11-26. Fakta sedí, ale „co jsem chtěl“ a „co si z toho beru“ musí být tvoje. Případy, které jsi sám nezažil nebo jim nerozumíš, smaž. Před odevzdáním smaž i tuhle poznámku.

### Případ 1: Prototyp, který se nedal vyhrát (2026-11-19)

**Co jsem chtěl:** Hratelný prototyp souboje: tři pruhy, balíček hráče a úředníka, střídání tahů.

**Co AI udělala špatně:** Pravidla fungovala, ale čísla vymyslela odhadem. Úředník nasazoval 3 karty za tah a hráč měl balíček 10 karet. Hra se skoro nedala vyhrát. Dvě třetiny partií končily tím, že hráči došly karty.

**Jak jsem to poznal:** Simulátor (`tools/balance_sim.py`) odehrál 10 000 partií a heuristický hráč vyhrál jen 9,6 %. *(Doplň: všiml sis toho už při hraní, nebo až ze simulace?)*

**Jak jsem to opravil:** Podle simulace se ukázalo, že nejsilnější páka je počet karet úředníka za tah, ne jeho HP. Tempo úředníka šlo na 2 a velikost balíčku se navázala na obtížnost. Výhra stoupla na 45–62 %.

**Commit / soubor:** `3c11e56`, `d0717f1`, `docs/balance.md`

**Co si z toho beru:**

### Případ 2: AI se odchýlila od zadání a řekla to jen v poznámce (2026-11-19)

**Co jsem chtěl:** V zadání (`docs/2026-11-19-menu-economy-spec.md`) stálo, že prodej ruky vymaže náhodnou kartu z balíčku a přidá debuff.

**Co AI udělala špatně:** Kartu z balíčku nemaže. Prodej ruky jen přidá debuff „Bez ruky“ (o kartu méně za tah). Odchylku zmínila až v sekci „Poznámky k implementaci“ na konci zadání, ne v odpovědi.

**Jak jsem to poznal:** Je to zapsané v sekci „Poznámky k implementaci“ ve spec dokumentu. *(Doplň, kdy a jak sis toho všiml.)*

**Jak jsem to opravil:** Nechal jsem to tak, protože balíček mezi případy nepřežívá a mazání karty by nemělo efekt. Rozhodnutí je teď zapsané v dokumentu.

**Commit / soubor:** `aeca01d`, `docs/2026-11-19-menu-economy-spec.md`

**Co si z toho beru:**

### Případ 3: Plán zaškrtnutý na nule, i když bylo hotovo (2026-11-26)

**Co jsem chtěl:** Plán v `docs/plan-menu-and-economy.md` měl ukazovat, co je hotové.

**Co AI udělala špatně:** Všechno z plánu naprogramovala, ale ani jeden z 21 checkboxů nezaškrtla. Dokument tvrdil „rozpracováno“.

**Jak jsem to poznal:** Když jsem nechal AI zkontrolovat stav projektu, porovnala plán s commity a všimla si nesouladu.

**Jak jsem to opravil:** Plán je zaškrtnutý a odkazuje na zadání s poznámkami k implementaci.

**Commit / soubor:** `docs/plan-menu-and-economy.md`

**Co si z toho beru:**

### Případ 4: Boss, kterého nešlo porazit (2026-11-26)

**Co jsem chtěl:** Jasnou výhru: kariérní žebříček pater úřadu, nahoře ředitel jako boss. Hra se má dát vyhrát.

**Co AI udělala špatně:** První verze pater měla ředitele s 26 HP a balíčkem 10 silných karet. Podle simulace ho hráč bez nákupů porazil ve 3,6 % případů. Celou kariéru bez nákupů vyhrál jen v 6 %. Znovu to stejné jako v případu 1: čísla odhadem.

**Jak jsem to poznal:** AI rozšířila simulátor na celou kariéru (patra, groše, obchod) a výsledek sama ukázala.

**Jak jsem to opravil:** Ladění podle simulace: ředitel má menší balíček (6) se silnými kartami a 24 HP, třetí patro je lehčí. Padělané razítko zdražilo z 18 na 22, protože bylo nejsilnější. Teď boss bez zboží 22 %, se zbožím přes 70 %, celá kariéra na Pondělí ráno 33 % bez nákupů a 92 % s nákupy.

**Commit / soubor:** `8e1af3a`, `docs/balance.md`

**Co si z toho beru:**

### Případ 5: Nový prvek UI vytlačil panel z obrazovky (2026-11-26)

**Co jsem chtěl:** Ve městě vidět, na kterém patře kariéry jsem.

**Co AI udělala špatně:** Přidala řádek se všemi čtyřmi patry do pravého panelu. Řádek byl moc široký: panel přetekl za okraj obrazovky a dole se useklo „Poplatek: 10 grošů“.

**Jak jsem to poznal:** Ze snímku obrazovky (`tools/screenshot.gd`), ne z kódu. Kód vypadal v pořádku.

**Jak jsem to opravil:** Kariéra se přesunula do záhlaví (žetony pater + název). Efekty se od tří kusů ukazují jako žetony ve dvou sloupcích, aby se vešly i nové buffy z baru.

**Commit / soubor:** `8e1af3a`, `scripts/city.gd`

**Co si z toho beru:**

### Případ 6: Hra se na cizím počítači nespustila podle README (2026-11-26)

**Co jsem chtěl:** Aby hru šlo spustit na cizím počítači podle README.

**Co AI udělala špatně:** Původní README říkalo jen `godot --path .`. Po čerstvém `git clone` to spadne na `Identifier "UiKit" not declared`, protože složka `.godot/` (cache tříd a importovaná grafika) není v gitu.

**Jak jsem to poznal:** AI naklonovala repozitář do prázdné složky a zkusila postup z README.

**Jak jsem to opravil:** README má krok `godot --headless --path . --import` (jen poprvé) a variantu přes editor, který import udělá sám. Ověřeno znovu na čistém klonu.

**Commit / soubor:** `README.md`

**Co si z toho beru:**

### Případ 7: AI špatně pochopila vlastní pravidla souboje (2026-11-26)

**Co jsem chtěl:** Automatické testy souboje.

**Co AI udělala špatně:** V testu přebytku útoku čekala, že po postupu zadní karty zaútočí znovu obě strany. Ve skutečnosti (podle `main.gd`) v dalším průchodu útočí jen postoupivší karta. Test tedy selhal, i když hra fungovala správně.

**Jak jsem to poznal:** Spuštění testů: `87 prošlo, 1 selhalo`.

**Jak jsem to opravil:** AI prošla `_resolve_combat` krok po kroku, spočítala přesná čísla a test opravila tak, aby kontroloval konkrétní hodnoty (6 a 8 ŽIV). Hru měnit nebylo potřeba.

**Commit / soubor:** `tests/test_runner.gd`

**Co si z toho beru:**
