# Arc-JSON – Schema & Anleitung

Ein **Story-Arc** ist genau **eine** Datei: `data/arcs/<id>.json`.
Sie enthält alles, was der Arc braucht. Um einen neuen Arc zu ergänzen:

1. Lege `data/arcs/<id>.json` an (am einfachsten `orange_town.json` kopieren).
2. Trage `<id>` in `ARC_ORDER` in `scripts/arc_manager.gd` ein (Reihenfolge der
   Reise). Steht die ID bereits dort (alle 28 Kanon-Arcs sind vorbereitet),
   genügt allein die Datei.
3. Fertig – kein weiterer Eingriff in den Kerncode nötig.

## Grundgerüst

```json
{
  "id": "orange_town",
  "title": "Orange Town – Der Clown am Kai",
  "intro": "Einleitungstext, der beim Betreten des Arcs gezeigt wird.",
  "start_map": "orange_stadt",
  "next_arc": "syrup_village",

  "enemies": { "...": { } },
  "quests":  [ { } ],
  "maps":    { "...": { } },
  "dialogues": { "...": [ ] }
}
```

## maps

```json
"maps": {
  "map_id": {
    "w": 20, "h": 15,
    "spawn": [x, y],
    "legend": { "G": "gras", "T": "baum", "W": "wasser", ... },
    "ground": [ "TTTT...", ... ],   // h Zeilen, je w Zeichen
    "over":   [ "....", ... ],       // optionaler Deko-Layer über dem Spieler
    "npcs":   [ ... ],
    "exits":  [ { "x":7, "y":14, "to":"andere_map", "tx":7, "ty":1 } ],
    "encounter": { "rate": 0.1, "max": 2, "pool": ["strolch"] }
  }
}
```

**Verfügbare Tile-Namen** (siehe `PlaceholderArt.TILE_ORDER`):
`gras, wasser, sand, weg, boden, baum, dach, wand, tuer, deck, steg, fels, blume`.
Solide (blockieren Bewegung): `wasser, baum, dach, wand, fels`.

## npcs

```json
{ "id": "makina", "x": 5, "y": 5, "dialogue": "makina_intro",
  "colors": { "skin":"f0c8a0", "hair":"5a3a8a", "shirt":"e8d05a", "pants":"806040" } }
```

`colors` sind Hex-Strings ohne `#`. `dialogue` verweist auf einen Eintrag unter
`"dialogues"`.

## dialogues

Ein Dialog ist ein Array aus Zeilen. Optional pro Zeile: `action` (sofort beim
Anzeigen) und `choices` (Auswahl).

```json
"makina_intro": [
  { "speaker": "Makina", "text": "Heute ist der große Tag?",
    "action": { "type": "start_quest", "id": "rd_main" } },
  { "speaker": "Kapu", "text": "Allerdings!",
    "choices": [
      { "text": "Los geht's!", "goto": 3 },
      { "text": "Warte noch.", "goto": 4, "action": { "type": "set_flag", "flag":"x" } }
    ] }
]
```

`goto` springt zur Zeilen-Nummer (0-basiert). Ohne `choices` geht es linear
weiter.

### Aktions-Typen

| type            | Felder                                   | Wirkung |
|-----------------|------------------------------------------|---------|
| `set_flag`      | `flag`, `value` (default true)           | Story-Schalter setzen |
| `recruit`       | `id`                                     | Crew-Mitglied aufnehmen (`kapu`,`zelos`,`nadia`) |
| `give_item`     | `id`, `count`                            | Item ins Inventar |
| `start_quest`   | `id`                                     | Quest aktivieren |
| `advance_quest` | `id`                                     | Quest einen Schritt weiter / abschließen |
| `heal_party`    | –                                        | ganze Crew heilen |
| `start_battle`  | `group` (Array Gegner-IDs), `boss`, `win_dialogue` | Kampf nach Dialogende starten; bei Sieg optional Folge-Dialog |
| `next_arc`      | –                                        | zum nächsten Arc wechseln |

## quests

```json
{
  "id": "rd_main",
  "name": "Setz die Segel!",
  "desc": "Kurzbeschreibung fürs Questlog.",
  "steps": [ { "id": "hafen", "text": "Hinweistext für Schritt 1" }, ... ],
  "reward": { "gold": 50, "exp": 20, "items": { "fleisch_spiess": 2 } }
}
```

Fortschritt steuerst du über `advance_quest`. Ist der letzte Schritt erreicht,
gilt die Quest als erledigt und die Belohnung wird vergeben.

## enemies (arc-spezifisch) & Bosse

```json
"enemies": {
  "rivax": { "name":"Boss Rivax", "max_kp":70, "atk":14, "def":6, "spd":6,
             "exp":40, "gold":80, "color":"9b2d2d",
             "skills":[ {"name":"Eisenkeule","power":1.7} ] }
}
```

Arc-Gegner haben Vorrang vor der globalen `data/enemies/enemies.json`. Ein Boss
ist einfach ein Gegner, der per `start_battle` mit `"boss": true` gerufen wird
(keine Flucht möglich).
