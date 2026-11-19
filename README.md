# Card Bureaucracy

2D karetní hra o byrokracii, Godot 4.7. Koncept je v [docs/game-concept.md](docs/game-concept.md).

## Spuštění

Otevři projekt v Godot 4.7 (`godot --path .`) nebo přes editor.

## Průchod hrou

`menu` → výběr obtížnosti → šarlatán prozradí heslo → `main` (první případ zdarma) → razítko → `city` (slumy) nebo rovnou `bar`, když po prohře nemáš na další kolo.

- **Město:** vlevo slumy s barem, vpravo groše, debuffy a buffy jako karty, dole úřad. Na úřadě se platí za další kolo.
- **Bar:** barmanovi řekneš „Jdu sem pro Honzu“ a za závěsem prodáš ruku (groše, ale o kartu méně za tah) nebo koupíš protézu.
- Stav hry drží autoload `GameState` (`scripts/game_state.gd`), sdílené UI je v `UiKit`, dialogy v `DialogBox`.

## Grafika

Pixel art v mřížce 640x360, zvětšený 2x na 1280x720. Veškerou grafiku (font, rámy, karty, ikony, portréty, pozadí) kreslí skript, nic se neupravuje ručně:

```
python3 tools/gen_assets.py      # přegeneruje assets/ včetně tools/gen_world.py (potřebuje Pillow)
godot --path . --import --headless
```

Paleta je nahoře v `tools/gen_assets.py` a stejné barvy používá `scripts/main.gd`. Ikona karty se bere z klíče `icon` v `CARD_POOL` / `ENEMY_POOL` (`assets/icons/card_<icon>.png`).

Snímek obrazovky bez klikání (volby jsou popsané v hlavičce skriptu):

```
godot --path . -s tools/screenshot.gd -- out=/tmp/shot.png scene=city setup=rich
```
