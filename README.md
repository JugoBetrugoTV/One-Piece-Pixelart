# ⚓ Grand Voyage

Ein **One-Piece-inspiriertes 2D-Pixelart-RPG** im Stil alter SNES-/Game-Boy-Spiele.
Top-Down, rundenbasierte Kämpfe, Story in Arcs. **Privates Fan-Projekt.**

> ⚠️ **Rechtlicher Hinweis:** Dies ist ein nicht-kommerzielles Fan-Projekt.
> Es werden **keine** originalen Sprites, keine Musik, keine Sounds und keine
> 1:1 kopierten Dialoge verwendet. Alle Grafiken werden **prozedural im Code**
> erzeugt (Platzhalter-Pixelart), alle Namen, Texte und Charaktere sind frei
> erfunden und nur vom Stil inspiriert.

---

## 🛠 Technik

| | |
|---|---|
| Engine | **Godot 4.6** |
| Sprache | **GDScript** |
| Typ | 2D Top-Down Pixelart RPG |
| Auflösung | 640×360 intern, pixel-perfekt skaliert |
| Kampf | rundenbasiert |
| Speichern | lokale Datei in `user://` |
| Grafik | prozedurale Platzhalter (keine externen Assets) |

Das Projekt ist **code-first** aufgebaut: Die Szenen-Dateien (`.tscn`) sind
absichtlich minimal, der Großteil (Tilemap, Sprites, UI, Kampf) wird zur
Laufzeit per GDScript erzeugt. Das hält das Projekt robust und leicht erweiterbar.

---

## ▶️ Starten

1. **Godot 4.6** herunterladen: <https://godotengine.org/download>
   (die normale „Standard"-Version, kein .NET nötig).
2. Godot starten → **Import** → diese `project.godot` auswählen → **Import & Edit**.
3. Oben rechts auf **▶ (Play / F5)** klicken.

> Das Spiel startet direkt mit `scenes/main/Main.tscn` (in `project.godot`
> hinterlegt). Beim ersten Start baut Godot kurz die `.godot/`-Cache-Ordner auf.

### Windows-Build (Export)

Editor → **Projekt → Exportieren → Hinzufügen → Windows Desktop**
→ Exportvorlagen bei Bedarf nachladen → **Projekt exportieren**.
Web-Export (HTML5) funktioniert ebenso über *Web*.

---

## 🎮 Steuerung

| Taste | Aktion |
|---|---|
| **WASD / Pfeiltasten** | Bewegen |
| **E / Enter / Leertaste** | Reden · Bestätigen · Text weiter |
| **Q** | Menü (Crew, Quests, Speichern/Laden) |
| **Esc** | Abbrechen / Menü schließen |

Im Kampf: **↑/↓** Auswahl, **E** bestätigen, **Esc** zurück.

---

## 🗺 Was ist drin (erste spielbare Version)

- **Startmenü** (Neues Spiel / Laden / Beenden)
- **Spielerbewegung** mit Kollision und Smooth-Follow-Kamera
- **Erste Insel** (Romance Dawn): Windmühlen-Dorf + Hafen, mit Map-Übergang
- **NPCs** mit JSON-Dialogsystem inkl. **Auswahlmöglichkeiten**
- **Hauptquest** mit Questlog und Belohnung
- **Crew-System**: Schwertkämpfer Zelos schließt sich an
- **Zufallskämpfe** + **Bosskampf** (rundenbasiert, EXP, Level-Ups, Items)
- **Speichern/Laden** in `user://savegame.json`
- **Arc-Übergang** zu Orange Town (zweiter Beispiel-Arc) und Platzhalter für
  alle weiteren Arcs

---

## 📁 Projektstruktur

```
/project.godot          – Engine-Konfiguration, Autoloads, Hauptszene
/autoload/
  GameState.gd          – globaler Spielzustand (Party, Inventar, Flags, Quests)
/scripts/
  game_manager.gd       – Hauptsteuerung (Menü, Welt, Übergänge, Pause)
  player_controller.gd  – Spielerbewegung
  npc.gd                – NPC mit Dialog-Trigger
  arc_manager.gd        – lädt Arc-JSONs, baut Maps
  dialogue_manager.gd   – JSON-Dialoge mit Choices + Story-Aktionen
  quest_manager.gd      – Questfortschritt
  battle_manager.gd     – rundenbasiertes Kampfsystem
  save_manager.gd       – Speichern/Laden
  placeholder_art.gd    – erzeugt ALLE Grafiken prozedural
  item_helper.gd        – Item-Datenbank
  enemy_db.gd           – globale Gegner-Datenbank
/scenes/
  main/Main.tscn        – Einstiegsszene
  player/Player.tscn    – Spielerfigur
  npc/NPC.tscn          – NPC-Vorlage
/data/
  arcs/                 – EIN JSON pro Story-Arc (romance_dawn, orange_town, ...)
  items/items.json      – Gegenstände
  enemies/enemies.json  – Standard-Gegner
/assets/                – (leer) für eigene Pixelart, Art wird sonst im Code erzeugt
/docs/ARC_SCHEMA.md     – wie man neue Arcs/Quests/Dialoge baut
ROADMAP.md              – alle 28 Arcs + Ausbauplan
```

---

## ➕ Neuen Story-Arc hinzufügen

Das wichtigste Designziel: **ein neuer Arc = eine einzige neue JSON-Datei.**

1. `data/arcs/orange_town.json` kopieren → z.B. `syrup_village.json`.
2. Inhalte anpassen (Maps, NPCs, Dialoge, Quest, Boss, `next_arc`).
3. Falls die ID noch nicht in `ARC_ORDER` (`scripts/arc_manager.gd`) steht,
   dort eintragen. Alle 28 Kanon-Arcs sind bereits vorbereitet.

Vollständiges Schema mit allen Feldern und Aktions-Typen:
**[`docs/ARC_SCHEMA.md`](docs/ARC_SCHEMA.md)**

---

## ⚠️ Hinweis zum Entwicklungsstand

Das Projekt wurde so geschrieben, dass es in **Godot 4.6** geöffnet und gestartet
werden kann; es konnte in der Build-Umgebung jedoch nicht im Editor „durchgespielt"
werden. Sollte beim ersten Start eine Kleinigkeit klemmen, steht in der
Godot-Konsole (unten) eine klare Fehlermeldung mit Datei und Zeile – melde sie
einfach, dann wird sie gezielt behoben.
