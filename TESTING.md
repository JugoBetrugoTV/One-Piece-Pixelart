# TESTING

Kurzanleitung zum automatisierten Rauchtest (Smoke-Test) des Projekts.

## Voraussetzung

- **Godot 4.6** (Standard-Version) – als ausführbare Datei verfügbar.
  Beispiel unten nutzt `godot` als Befehl; ersetze ihn ggf. durch den vollen
  Pfad zu deiner Godot-Binärdatei.

## Smoke-Test starten

Im Projektordner (dort, wo `project.godot` liegt):

```bash
# 1) Einmal importieren (baut den .godot-Cache, prüft alle Skripte/Szenen)
godot --headless --import

# 2) Rauchtest ausführen
godot --headless res://tools/SmokePilot.tscn
```

Der Test läuft komplett **ohne Fenster** (headless) und beendet sich selbst.

## Was bedeutet „22/22 checks"?

Der Rauchtest (`tools/smoke_pilot.gd`) fährt die Kernsysteme programmatisch durch
und macht **22 Einzelprüfungen**. Jede Zeile ist entweder

```
  ok  : <Beschreibung>      # Prüfung bestanden
  FAIL: <Beschreibung>      # Prüfung fehlgeschlagen
```

Am Ende steht:

```
==== SMOKE-TEST FERTIG: 0 Fehler ====
```

- **0 Fehler / Exit-Code 0** → alle 22 Prüfungen grün (22/22). Basis ist stabil.
- **Exit-Code > 0** → so viele Prüfungen sind fehlgeschlagen; die `FAIL:`-Zeilen
  nennen genau, welche.

Geprüft werden u.a.:
1. Alle Autoloads erreichbar
2. Neues Spiel / Startparty
3. Arc-Dateien laden (vorhandene + Platzhalter erkannt)
4. TileSet mit Kollisionsschicht
5. Spieler + NPCs platziert, Spawn-Tile korrekt
6. Map-Wechsel (Dorf → Hafen)
7. Speichern/Laden (Gold + Position)
8. **Gegner-Daten unverändert nach Kampf** (frische Kopie pro Kampf)
9. Ein Kampf läuft bis „Sieg"
10. Ein Dialog mit Aktion (`give_item`) läuft bis zum Ende

> Hinweis: Der Smoke-Test prüft **Logik und Aufbau**, nicht die Optik oder die
> Tastatur-Bedienung. Dafür ist der manuelle Editor-Test nötig (siehe
> `TODO_NEXT.md`).

## Was der Smoke-Test NICHT abdeckt

Siehe `KNOWN_ISSUES.md` – v.a. Optik der Pixelart, Spielgefühl, interaktive
Menü-/Dialog-/Kampf-Bedienung, Exporte.

## Fehler aus der Godot-Konsole melden

Wenn beim Editor-Start oder im Spiel etwas schiefgeht, zeigt Godot unten die
**Konsole / „Debugger" → „Errors"**. Eine Fehlermeldung sieht so aus:

```
SCRIPT ERROR: <Beschreibung>
   at: <Funktion> (res://scripts/<datei>.gd:<Zeile>)
```

Zum Melden bitte mitschicken:
1. Die **komplette Fehlerzeile** inkl. `res://...:<Zeile>` (Datei + Zeilennummer).
2. **Was du gemacht hast**, als der Fehler kam (z.B. „NPC angesprochen",
   „Kampf gestartet", „gespeichert").
3. Falls möglich: ob der Fehler **einmalig** oder **bei jedem Frame** auftritt
   (steht oft als `(x N)` hinter der Meldung).

Mit Datei + Zeile + Auslöser lässt sich fast jeder Bug gezielt beheben.
