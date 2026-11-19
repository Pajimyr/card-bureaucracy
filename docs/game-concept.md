# Card Bureaucracy: koncept hry

## Rámec
- **Žánr:** 2D karetní hra, boj proti úřadům.
- **Téma:** kariérní žebřík v dystopickém městě. Nahoře futuristické věže, dole ulice s drogami a bezdomovci.
- **Hráč:** občan s úředním případem. Cílem je dostat se na vrchol kariéry a zjistit, že peníze nejsou všechno.
- **Engine:** Godot 4.7, 2D.

## Smyčka
- **Level = případ.** Dva běžní úředníci a jeden boss. Porazíš je všechny a jdeš dál.
- **Tahy.** Hraje se po tazích. Úředník je vždy druhý a začíná útočit.
- **Energie na kolo** omezuje, kolik karet můžeš zahrát.
- **Boj ve třech pruzích.** Horní řada slotů jsou úředníci, spodní řada jsou tvoje sloty. Každý pruh je jedna srážka karet.
- **Úředník** má vlastní balíček karet a hraje proti tobě.

## Inventář
- Náhodný balíček. Karty se po použití vracejí zpět a mohou přijít znovu.
- Karty s omezeným počtem si musíš koupit na černém trhu.
- Po prohře si nakupuješ zpět karty, které jsi v levelu používal nejčastěji.

## Gamba
- Když ti dojdou karty, můžeš ztratit tah, nebo zahrát ruletu.
- Výhra dá karty, prohra debuff.

## Černý trh, deformity a měna
- Debuffy se léčí na černém trhu za měnu, kterou získáváš výhrami v levelech.
- Deformity se hromadí a zůstávají vidět i po opravě, jako špatná plastika.
- Hra nekončí, pokračuješ s tím, co máš.

## Prohra levelu
- Deformity a debuffy zůstávají.
- Peníze odcházejí úřadům, které si je berou za nic.
- Karty z inventáře se vrátí za poplatek na černém trhu.

## Otevřené věci
- Přesné staty karet a čísla.
- Konkrétní seznam debuffů a deformit.
- Počet levelů a postup po kariérních příčkách.
- Vzhled úředníků, bossů a grafika karet.
- Ekonomika měny a cen na černém trhu.
