# Known Issues / Teststatus

Stand: Basis-Stabilisierung. Romance Dawn ist headless verifiziert; bevor Arc 3
(Syrup Village) gebaut wird, hier ehrlich der Teststatus.

> **Versions-Status:** Der automatisierte Smoke-Test wurde mit **Godot 4.6.stable**
> (Zielversion) ausgeführt – Import fehlerfrei, 22/22 Prüfungen grün. Zusätzlich
> gegengeprüft mit 4.4.1. **Der manuelle Godot-4.6-Editor-Test (Optik, Bedienung,
> kompletter Durchlauf) steht weiterhin aus.**

## ✅ Automatisiert getestet (Godot 4.6.stable, headless)

- Projekt-Import ohne Script-/Resource-Fehler (alle 13 `.gd`, alle Szenen).
- Autoloads korrekt registriert und erreichbar (GameState, ArcManager,
  SaveManager, QuestManager, DialogueManager, BattleManager).
- Main Scene gesetzt und ladbar (`scenes/main/Main.tscn`).
- Input-Actions zur Laufzeit registriert (move_*, interact, cancel, menu).
- Map-Aufbau via **TileMapLayer** für beide Maps (Dorf + Hafen).
- **TileSet-Kollisionsschicht** vorhanden (1 Physik-Layer, solide Tiles).
- Map-Wechsel (NPCs werden korrekt neu aufgebaut).
- **Speichern/Laden** in `user://savegame.json` (Gold + Position round-trip).
- **Gegner-Daten werden durch einen Kampf nicht mutiert** (frische Kopie pro Kampf).
- Ein **Kampf** läuft bis „Sieg" durch (UI-Aufbau inkl. prozeduraler Sprites).
- Ein **Dialog mit Aktion** (`give_item`) läuft bis zum Ende und wirkt.

Rauchtest: `godot --headless res://tools/SmokePilot.tscn` (Exit-Code 0 = ok).

## ⬜ Noch NICHT getestet (manuell im Editor verifizieren)

Diese Dinge brauchen einen echten Editor-/Render-Lauf mit Tastatur und Bildschirm:

1. **Optik der Pixelart** – die Sprites/Tiles werden prozedural erzeugt; ob sie
   „schön" aussehen, ist Geschmackssache und visuell nicht geprüft.
2. **Spielgefühl der Bewegung** – Geschwindigkeit, Kollision an Kanten,
   Kamera-Smoothing (Werte sind gesetzt, aber nicht „erfühlt").
3. **Interaktive Bedienung** – Menü-Navigation, Dialog-Auswahl (Choices) und
   Kampf-Menü per Tastatur (Logik ist getestet, das visuelle Hervorheben nicht).
4. **Kampf-Detailpfade** – Item-Ziel-Auswahl, Spezialangriff auf alle Gegner,
   Flucht, Party-Wipe → Game Over → Hauptmenü (Logik vorhanden, nicht durchgeklickt).
5. **Zufallskämpfe im Spiel** – Auslöserate/Häufigkeit beim echten Laufen.
6. **Vollständiger Romance-Dawn-Durchlauf** Dorf → Hafen → Zelos rekrutieren →
   Rivax-Boss → Arc-Übergang zu Orange Town (Einzelbausteine getestet, der
   komplette Spieler-Pfad am Stück nicht).
7. **Layout/Schriftgrößen der UI** auf 640×360 – Texte könnten je nach Inhalt
   über Ränder laufen; Standard-Theme, keine Feinabstimmung.
8. **Exporte**: Windows-Desktop und Web (HTML5) sind nicht gebaut/getestet
   (benötigen Export-Templates).
9. **Audio**: bewusst keins vorhanden (keine fremden Assets).

## 🔧 Offene technische Punkte

- **Default-Branch**: `main` ist gepusht, aber der Default-Branch des Repos
  muss ggf. noch manuell auf `main` gestellt werden
  (GitHub → Settings → General → Default branch), falls nicht automatisch
  geschehen. Programmatisch war das in dieser Umgebung nicht möglich.
- **Godot-Zielversion**: Projekt deklariert 4.6 (`project.godot`) und wurde
  headless mit **4.6.stable** verifiziert. Der interaktive Editor-Test (Render +
  Tastatur) steht noch aus.
- **Kamera bei kleinen Maps**: Maps (320×240) sind kleiner als das Sichtfenster
  (640×360); die Kamera-Limits führen zu Rand-/Letterbox-Bereichen. Funktional
  ok, optisch evtl. später anpassen.
- **`tools/`** (SmokePilot) ist ein reines Entwickler-Testwerkzeug und nicht
  Teil des Spiels.

## Vorgehen bei Fehlern

Beim ersten Editor-Start die **Godot-Konsole** (unten) beachten: Fehler kommen
mit Datei + Zeile. Diese Meldung melden – dann gezielt fixen.
