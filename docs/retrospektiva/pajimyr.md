# Retrospektiva: Pajimyr

> **DOPLŇ SÁM.** Retrospektiva jsou tvoje názory, ty za tebe AI psát nemá. Pod každou otázkou jsou jen **podklady**: fakta z repozitáře, o která se můžeš opřít. Vyber, s čím souhlasíš, napiš to vlastními slovy a podklady smaž.

## Co bych udělal jinak

*Podklady:*
- Čísla (HP, balíčky, ceny) se dvakrát nastavila odhadem a dvakrát se ukázalo, že hra nejde vyhrát (deník, případy 1 a 4). Simulátor existoval od 19. 11., ale použil se až zpětně.
- Jasná podmínka výhry chyběla až do 26. 11. Hra měla menu, bar a ruletu dřív než cíl.
- Plán v `docs/` se přestal aktualizovat, dokumentace se rozešla s kódem (deník, případ 3).
- Testy vznikly až na konci.
- Repozitář nemá remote a všechny commity jsou pod jedním jménem.

## Kde AI pomohla

*Podklady:*
- Grafika: celý pixel art (font, karty, ikony, portréty, pozadí) kreslí Python skripty v `tools/`, které napsala AI.
- Simulátor balance: tisíce her za minutu místo ručního zkoušení.
- Rychlý prototyp: první hratelná verze souboje za jeden den (commity 19. 11.).
- Nástroj na snímky obrazovky (`tools/screenshot.gd`) chytil chybu v layoutu, kterou v kódu vidět nebylo.

## Kde AI překážela

*Podklady:*
- Vymýšlela čísla bez ověření a tvářila se, že jsou v pořádku.
- Odchylky od zadání psala do poznámek místo toho, aby se zeptala (deník, případ 2).
- Nehlídala dokumentaci a postup spuštění na čistém počítači (deník, případy 3 a 6).
- Kód, kterému člověk nerozumí, se špatně obhajuje: je potřeba ho projít (viz `docs/obhajoba-podklady.md`).

## Jedna věc, kterou si odnáším
