# 🗺 Roadmap – Grand Voyage

Die komplette Reise wird als Folge von **Arcs** erzählt. Jeder Arc ist eine
eigene JSON-Datei in `data/arcs/` (siehe [`docs/ARC_SCHEMA.md`](docs/ARC_SCHEMA.md)).
Die Reihenfolge steht in `ARC_ORDER` (`scripts/arc_manager.gd`).

## Status der Arcs

| # | Arc | Datei | Status |
|---|-----|-------|--------|
| 1 | Romance Dawn | `romance_dawn.json` | ✅ spielbare Demo |
| 2 | Orange Town | `orange_town.json` | ✅ kompaktes Beispiel |
| 3 | Syrup Village | `syrup_village.json` | ⬜ Platzhalter (Datei anlegen) |
| 4 | Baratie | – | ⬜ |
| 5 | Arlong Park | – | ⬜ |
| 6 | Loguetown | – | ⬜ |
| 7 | Reverse Mountain | – | ⬜ |
| 8 | Whisky Peak | – | ⬜ |
| 9 | Little Garden | – | ⬜ |
| 10 | Drum Island | – | ⬜ |
| 11 | Alabasta | – | ⬜ |
| 12 | Jaya | – | ⬜ |
| 13 | Skypia | – | ⬜ |
| 14 | Water 7 | – | ⬜ |
| 15 | Enies Lobby | – | ⬜ |
| 16 | Thriller Bark | – | ⬜ |
| 17 | Sabaody | – | ⬜ |
| 18 | Amazon Lily | – | ⬜ |
| 19 | Impel Down | – | ⬜ |
| 20 | Marineford | – | ⬜ |
| 21 | Post-War | – | ⬜ |
| 22 | Fishman Island | – | ⬜ |
| 23 | Punk Hazard | – | ⬜ |
| 24 | Dressrosa | – | ⬜ |
| 25 | Zou | – | ⬜ |
| 26 | Whole Cake Island | – | ⬜ |
| 27 | Wano | – | ⬜ |
| 28 | Egghead | – | ⬜ |

> Solange eine Arc-Datei fehlt, zeigt der Arc-Übergang automatisch einen
> freundlichen Platzhalter-Dialog an – das Spiel bleibt also immer lauffähig.

## Wie es weitergeht (empfohlene Reihenfolge)

### Phase 1 – Fundament (erledigt)
- [x] Projektgerüst, Autoloads, Eingabe
- [x] Spielerbewegung + Kollision + Kamera
- [x] Tilemap aus JSON, Map-Übergänge
- [x] NPC-Dialogsystem mit Choices und Story-Aktionen
- [x] Quest-System + Questlog
- [x] Rundenbasiertes Kampfsystem (EXP, Level, Items, Boss)
- [x] Speichern/Laden
- [x] Romance Dawn als spielbare Demo + Arc-Erweiterungssystem

### Phase 2 – Inhalte ausbauen
- [ ] Arcs 3–5 (Syrup Village, Baratie, Arlong Park) als JSON anlegen
- [ ] Mehr Crew-Mitglieder (Vorlagen in `GameState.CREW_TEMPLATES` ergänzen,
      jeweils mit eigenem Skill und Charakterzug)
- [ ] Shop-NPCs (Kaufen/Verkaufen über `ItemHelper`)
- [ ] Ausrüstung im Pausenmenü an-/ablegen (Felder `weapon`/`armor` existieren)

### Phase 3 – Systeme vertiefen
- [ ] **Schiffs-/Seereise-System**: eigene „Weltkarten"-Map mit freischaltbaren
      Inseln; Reisen löst Zufallsbegegnungen auf See aus
      (das `encounter`-Feld funktioniert bereits auf jeder Map)
- [ ] Schiff-Upgrades (neue Member-/Schiffs-Stats)
- [ ] Animierte Lauf-Frames für Sprites (in `PlaceholderArt.make_actor`
      einen zweiten Frame ergänzen)
- [ ] Cutscene-Kamera-Fahrten zwischen Dialogzeilen
- [ ] Soundsystem (eigene, selbst erstellte Sounds in `assets/audio/`)

### Phase 4 – Politur
- [ ] Eigene, von Hand gezeichnete Pixelart in `assets/` (ersetzt Platzhalter)
- [ ] Menü-/UI-Theme (Godot `Theme`-Ressource)
- [ ] Mehrere Speicherslots
- [ ] Optionsmenü (Lautstärke, Fenstergröße)

## Tipp zum Erweitern

Am schnellsten kommt neuer Inhalt durch **Kopieren** rein:
`data/arcs/orange_town.json` ist die kleinste vollständige Vorlage – Map,
NPC, Quest, Boss, Arc-Übergang in unter 100 Zeilen.
