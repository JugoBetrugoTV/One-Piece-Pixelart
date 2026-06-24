# assets/

Dieses Projekt erzeugt **alle Grafiken prozedural im Code**
(`scripts/placeholder_art.gd`). Es liegen daher bewusst **keine** Binär-Assets
(PNG, Aseprite, WAV, ...) im Repository:

- garantiert **keine** originalen One-Piece-Sprites, -Sounds oder -Musik
- alles ist selbst erzeugt und frei veränderbar
- das Projekt läuft ohne externe Asset-Dateien

## Wenn du später echte eigene Pixelart einbauen willst

1. Lege deine selbst gezeichneten PNGs hier ab, z.B.:
   - `assets/sprites/` – Charaktere, Gegner, Bosse
   - `assets/tilesets/` – Tile-Atlanten
   - `assets/ui/` – Menü-Grafiken
   - `assets/audio/` – eigene Musik/Sounds
2. Importiere sie im Godot-Editor (Import-Tab → Filter auf **Nearest** für
   knackige Pixelart).
3. Ersetze die entsprechenden `PlaceholderArt.make_*` / `tile_atlas()`-Aufrufe
   durch `preload("res://assets/...")`.

Wichtig bleibt: **nur eigene Assets** verwenden, keine originalen Vorlagen.
