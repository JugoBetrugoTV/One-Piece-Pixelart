# TODO NEXT – nächste Schritte (in dieser Reihenfolge)

Die Basis ist headless mit **Godot 4.6** verifiziert (Smoke-Test 22/22).
Bevor neue Inhalte gebaut werden, muss die Demo **einmal real spielbar** sein.

> **Regel:** Kein weiterer Story-Arc (Syrup Village / Arc 3), bis Punkt 1–3
> erledigt sind und Romance Dawn in Godot 4.6 sauber startet und durchspielbar ist.

## 1. Lokaler Godot-4.6-Editor-Test  ⏳ als Nächstes
- Projekt in **Godot 4.6** öffnen (`Import` → `project.godot`).
- Mit **▶ (F5)** starten.
- Prüfen:
  - Startmenü erscheint, Navigation mit ↑/↓ + **E** funktioniert.
  - „Neues Spiel" startet, Spieler bewegt sich mit **WASD**.
  - Kollision an Bäumen/Wänden, Kamera folgt sauber.
  - NPC ansprechen mit **E** → Dialog erscheint, Auswahl bedienbar.
  - **Q** öffnet Pause/Questlog, Speichern/Laden funktioniert.
- Godot-Konsole (unten) auf Fehler beobachten.

## 2. Romance Dawn einmal komplett manuell durchspielen
- Dorf → mit Makina reden (Quest startet, Item erhalten).
- Pfad nach Süden zum **Hafen**.
- **Zelos** ansprechen und rekrutieren (Crew = 2).
- Zufallskämpfe testen (treten sie auf? gewinnbar?).
- **Rivax-Boss** besiegen → Sieg-Dialog → Arc-Übergang zu **Orange Town**.
- Unterwegs: Kampf-Menü (Angriff/Spezial/Item/Flucht), Level-Up, Game-Over-Pfad.

## 3. Bugs fixen
- Jeden gefundenen Fehler melden (siehe `TESTING.md` → „Fehler melden":
  Datei + Zeile + Auslöser).
- Fixes auf einem Branch, per PR nach `main`.
- Nach jedem Fix erneut Smoke-Test laufen lassen (`TESTING.md`).

## 4. Erst danach: Syrup Village / Arc 3
- Wenn die Demo stabil und spielbar ist:
  `data/arcs/orange_town.json` als Vorlage kopieren → `syrup_village.json`.
- Schema: `docs/ARC_SCHEMA.md`. Reihenfolge/Status: `ROADMAP.md`.

---

### Schnell-Checkliste
- [ ] 1. Editor-Test in Godot 4.6 (startet & läuft)
- [ ] 2. Romance Dawn komplett durchgespielt
- [ ] 3. Gefundene Bugs gefixt (Smoke-Test wieder grün)
- [ ] 4. Freigabe → Arc 3 (Syrup Village) bauen
