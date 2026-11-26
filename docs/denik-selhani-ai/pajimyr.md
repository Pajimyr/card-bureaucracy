# Deník selhání AI: Pajimyr

Na projektu jsem dělal sám, s AI (Claude) jako pomocníkem na kód, grafiku a dokumenty. Sem si píšu, kde to AI pokazila, jak jsem na to přišel a co jsem s tím udělal.

### Případ 1: Prototyp, který skoro nešel vyhrát (19. 11.)

**Co jsem chtěl:** Hratelný prototyp souboje. Tři pruhy, můj balíček proti balíčku úředníka, střídání tahů.

**Co AI udělala špatně:** Pravidla fungovala, jenže čísla vymyslela od oka. Úředník dával 3 karty za tah, já měl balíček jen 10 karet. Hra se skoro nedala vyhrát, většinou mi prostě došly karty.

**Jak jsem to poznal:** Nechal jsem napsat simulátor (`tools/balance_sim.py`), který odehrál 10 000 her. Výhra vyšla 9,6 %. Takže to nebyl můj skill, hra byla fakt rozbitá.

**Jak jsem to opravil:** Simulace ukázala, že nejvíc rozhoduje, kolik karet úředník dá za tah, a ne jeho HP. Snížil jsem to na 2 a velikost balíčku navázal na obtížnost. Výhra pak vyšla 45 až 62 % podle obtížnosti.

**Commit / soubor:** `3c11e56`, `d0717f1`, `docs/balance.md`

**Co si z toho beru:** Čísla od AI neberu jako hotovou věc. Bez simulace nebo testu je to jen tip.

### Případ 2: AI udělala něco jinak, než jsem zadal, a řekla to jen v poznámce (19. 11.)

**Co jsem chtěl:** V zadání (`docs/2026-11-19-menu-economy-spec.md`) bylo, že prodej ruky v baru smaže náhodnou kartu z balíčku a přidá debuff.

**Co AI udělala špatně:** Kartu nemaže. Prodej ruky jen přidá debuff „Bez ruky“ (o kartu míň za tah). Že to udělala jinak, napsala až dole do „Poznámek k implementaci“, ne rovnou do odpovědi.

**Jak jsem to poznal:** Při čtení dokumentu, sekce s poznámkami na konci.

**Jak jsem to opravil:** Nakonec jsem to tak nechal, protože balíček mezi případy nepřežívá a mazání karty by stejně nic nedělalo. Je to ale moje rozhodnutí a v dokumentu je zapsané.

**Commit / soubor:** `aeca01d`, `docs/2026-11-19-menu-economy-spec.md`

**Co si z toho beru:** Číst i konec dokumentu. Odchylky od zadání AI klidně schová do poznámek.

### Případ 3: Plán říkal „rozpracováno“, i když bylo hotovo (26. 11.)

**Co jsem chtěl:** Mít v `docs/plan-menu-and-economy.md` přehled, co je hotové.

**Co AI udělala špatně:** Všechno z plánu naprogramovala, ale ani jeden z 21 checkboxů nezaškrtla. Dokument pořád tvrdil, že je to rozpracované.

**Jak jsem to poznal:** Když jsem po týdnu chtěl vědět, jaký je stav projektu, nechal jsem AI porovnat plán s commity. Nesedělo to.

**Jak jsem to opravil:** Plán je zaškrtnutý a odkazuje na zadání s poznámkami.

**Commit / soubor:** `a424082`

**Co si z toho beru:** Dokumentaci musím hlídat sám, AI ji sama od sebe neaktualizuje.

### Případ 4: Boss, kterého nešlo porazit (26. 11.)

**Co jsem chtěl:** Jasnou výhru. Hra měla jen prohru a já potřeboval, aby se dala vyhrát. Přišel kariérní žebříček: čtyři patra úřadu a nahoře ředitel jako boss.

**Co AI udělala špatně:** Zase čísla od oka, stejně jako v prvním případu. Ředitel měl 26 HP a 10 silných karet. Bez nákupů v baru ho hráč porazil ve 3,6 % her a celou kariéru vyhrál v 6 %. Výhra tam teda byla, ale jen na papíře.

**Jak jsem to poznal:** Simulátor se rozšířil na celou kariéru (patra, groše, obchod) a ukázal to černé na bílém.

**Jak jsem to opravil:** Ladilo se podle simulace. Ředitel má menší balíček (6), ale silné karty, a 24 HP. Třetí patro je lehčí. Padělané razítko zdražilo z 18 na 22 grošů, protože bylo moc silné. Teď kariéra na Pondělí ráno vychází na 33 % bez nákupů a 92 % s nákupy. To mi přišlo dobré, bar má smysl.

**Commit / soubor:** `8e1af3a`, `docs/balance.md`

**Co si z toho beru:** Stejnou chybu udělala dvakrát. Simulátor jsem měl používat od začátku, ne až když je problém.

### Případ 5: Nový prvek UI vytlačil panel z obrazovky (26. 11.)

**Co jsem chtěl:** Ve městě vidět, na kterém jsem patře.

**Co AI udělala špatně:** Přidala do pravého panelu řádek se všemi čtyřmi patry. Byl moc široký, panel utekl za okraj obrazovky a dole se useklo „Poplatek: 10 grošů“.

**Jak jsem to poznal:** Ze screenshotu (`tools/screenshot.gd`). V kódu to vypadalo úplně v pohodě.

**Jak jsem to opravil:** Kariéra je teď v záhlaví (žetony pater a název patra). Efekty se od tří kusů ukazují jako malé žetony ve dvou sloupcích, aby se vešly i nové věci z baru.

**Commit / soubor:** `8e1af3a`, `scripts/city.gd`

**Co si z toho beru:** UI kontrolovat očima, ne jen číst kód.

### Případ 6: Na cizím počítači to nešlo spustit podle README (26. 11.)

**Co jsem chtěl:** Aby hru šlo spustit na cizím počítači podle README. Je to v definici hotovo.

**Co AI udělala špatně:** V README bylo jen `godot --path .`. Po čerstvém `git clone` to spadne na `Identifier "UiKit" not declared`, protože složka `.godot/` (cache a importovaná grafika) v gitu není. U mě to fungovalo, protože jsem ji měl.

**Jak jsem to poznal:** Repo se naklonovalo do prázdné složky a zkusil se přesně postup z README.

**Jak jsem to opravil:** V README je teď krok `godot --headless --path . --import` (jen poprvé) a varianta přes editor, který import udělá sám. Znovu ověřeno na čistém klonu, hra i testy jedou.

**Commit / soubor:** `174b36c`, `README.md`

**Co si z toho beru:** „U mě to jede“ nic neznamená. Zkoušet na čistém klonu.

### Případ 7: AI nepochopila vlastní pravidla souboje (26. 11.)

**Co jsem chtěl:** Automatické testy, ať mám něco víc než jen proklikávání.

**Co AI udělala špatně:** V testu souboje čekala, že po postupu zadní karty zaútočí znovu obě strany. Jenže podle jejího vlastního kódu v `main.gd` v dalším kole útočí jen ta karta, co postoupila. Test spadl, i když hra byla v pořádku.

**Jak jsem to poznal:** Spustil jsem testy a vyšlo `87 prošlo, 1 selhalo`.

**Jak jsem to opravil:** Souboj se prošel krok po kroku, spočítala se přesná čísla a test teď kontroluje konkrétní hodnoty (6 a 8 ŽIV). Hru nebylo potřeba měnit. Teď jede 89 z 89.

**Commit / soubor:** `4869ad3`, `tests/test_runner.gd`

**Co si z toho beru:** Když spadne test, nemusí být chyba ve hře. Může být v testu. Je potřeba zjistit, kdo má pravdu.
