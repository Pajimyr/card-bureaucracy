# Card Bureaucracy

2D karetní hra o byrokracii, Godot 4.7. Koncept je v [docs/game-concept.md](docs/game-concept.md).

## Spuštění

Otevři projekt v Godot 4.7 (`godot --path .`) nebo přes editor.

## Grafika

Pixel art v mřížce 640x360, zvětšený 2x na 1280x720. Veškerou grafiku (font, rámy, karty, ikony, portréty, pozadí) kreslí skript, nic se neupravuje ručně:

```
python3 tools/gen_assets.py      # přegeneruje assets/ (potřebuje Pillow)
godot --path . --import --headless
```

Paleta je nahoře v `tools/gen_assets.py` a stejné barvy používá `scripts/main.gd`. Ikona karty se bere z klíče `icon` v `CARD_POOL` / `ENEMY_POOL` (`assets/icons/card_<icon>.png`).

Snímek obrazovky bez klikání: `godot --path . -s tools/screenshot.gd -- /tmp/shot.png 60 [enemy|select|end_win|end_lose]`.
