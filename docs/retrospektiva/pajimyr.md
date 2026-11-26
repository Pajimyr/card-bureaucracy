# Retrospektiva: Pajimyr

## Co bych udělal jinak

Hlavně bych si dřív ujasnil cíl hry. Měl jsem menu, bar, ruletu a animace, ale až na konci jsem zjistil, že se hra nedá vyhrát. Výhru jsem měl vymyslet jako první.

Simulátor balance jsem měl od 19. 11., ale použil jsem ho až pokaždé, když už byl problém. Dvakrát se mi stalo, že čísla od AI udělala hru skoro nevyhratelnou. Příště nastavím čísla a hned pustím simulaci.

Testy a README bych psal průběžně, ne na konci. A dokumentaci bych aktualizoval hned. Plán v `docs/` ukazoval „rozpracováno“, i když bylo dávno hotovo.

## Kde AI pomohla

Grafika. Celý pixel art (font, karty, ikony, portréty, pozadí) kreslí Python skripty, které napsala AI. Sám bych to kreslil týden a nevypadalo by to tak jednotně.

Rychlost. První hratelný souboj byl hotový za den. Menu, město a bar taky za den.

Simulátor a screenshoty. Simulátor odehraje tisíce her za minutu, takže vidím, jestli se hra dá vyhrát, a nemusím to zkoušet ručně. Screenshoty bez klikání zase chytily chybu v layoutu, která v kódu vidět nebyla.

## Kde AI překážela

Vymýšlela čísla a tvářila se, že jsou v pohodě. Dvakrát nevyhratelná hra, pokaždé ze stejného důvodu.

Když udělala něco jinak, než jsem chtěl, napsala to do poznámek na konec, místo aby se zeptala.

Nehlídá věci kolem: dokumentaci, postup spuštění na cizím počítači. Kód napíše, ale jestli to jde spustit po naklonování, jsem musel řešit zvlášť.

A je to hodně kódu najednou. Abych ho uměl obhájit, musím ho projít sám. Jinak nevím, co v projektu vlastně mám.

## Jedna věc, kterou si odnáším

AI je rychlá, ale musím jí kontrolovat výsledky. Ne jestli kód vypadá dobře, ale jestli hra opravdu funguje: simulace, testy, screenshot, čistý klon.
