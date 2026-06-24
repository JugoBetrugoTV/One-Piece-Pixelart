extends Node
## ============================================================================
## ArcManager (Autoload)
## ----------------------------------------------------------------------------
## Lädt die Story-Arcs aus data/arcs/<id>.json. Jeder Arc ist EINE in sich
## geschlossene JSON-Datei mit Maps, NPCs, Dialogen, Quests, Gegnern und Boss.
##
## So lautet die wichtigste Erweiterungsregel des Projekts:
##   -> Neuen Arc hinzufügen = neue JSON-Datei in data/arcs/ anlegen
##      und in ARC_ORDER eintragen. KEIN Eingriff in den Kerncode nötig.
##
## Aufbau einer Arc-JSON (Kurzform, vollständiges Beispiel: romance_dawn.json):
## {
##   "id": "...", "title": "...", "intro": "...",
##   "start_map": "...",
##   "next_arc": "orange_town",
##   "maps": { "<map_id>": { "w","h","ground"[],"over"[],"spawn"[x,y],
##                            "npcs"[], "exits"[], "encounter"{} } },
##   "dialogues": { "<dlg_id>": [ {speaker,text,choices?} ] },
##   "quests": [ { id, name, desc, steps[] } ],
##   "enemies": { "<id>": {...} },   # arc-spezifische Gegner (optional)
##   "boss": { ... }
## }
## ============================================================================

## Reihenfolge aller Arcs. Die komplette One-Piece-Reise ist hier als Roadmap
## abgebildet; spielbar/implementiert ist zunächst Romance Dawn. Weitere Arcs
## bekommen einfach eine eigene JSON-Datei.
const ARC_ORDER := [
	"romance_dawn", "orange_town", "syrup_village", "baratie", "arlong_park",
	"loguetown", "reverse_mountain", "whisky_peak", "little_garden", "drum_island",
	"alabasta", "jaya", "skypia", "water_7", "enies_lobby", "thriller_bark",
	"sabaody", "amazon_lily", "impel_down", "marineford", "post_war",
	"fishman_island", "punk_hazard", "dressrosa", "zou", "whole_cake_island",
	"wano", "egghead"
]

var current: Dictionary = {}   # die geladenen Daten des aktuellen Arcs

func arc_path(id: String) -> String:
	return "res://data/arcs/%s.json" % id

func arc_exists(id: String) -> bool:
	return FileAccess.file_exists(arc_path(id))

## Lädt einen Arc und gibt seine Daten zurück (oder ein leeres Dictionary).
func load_arc(id: String) -> Dictionary:
	if not arc_exists(id):
		push_warning("Arc-Datei fehlt (noch nicht implementiert): " + id)
		current = {}
		return current
	var text := FileAccess.get_file_as_string(arc_path(id))
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Arc-JSON ungültig: " + id)
		current = {}
		return current
	current = parsed
	GameState.current_arc = id
	return current

## Liefert eine Map-Definition des aktuellen Arcs.
func get_map(map_id: String) -> Dictionary:
	if current.is_empty():
		return {}
	return current.get("maps", {}).get(map_id, {})

## Liefert einen Dialog (Array aus Zeilen) des aktuellen Arcs.
func get_dialogue(dlg_id: String) -> Array:
	if current.is_empty():
		return []
	return current.get("dialogues", {}).get(dlg_id, [])

## Liefert die nächste Arc-ID (für den Story-Übergang).
func next_arc_id() -> String:
	if current.has("next_arc"):
		return str(current["next_arc"])
	var idx := ARC_ORDER.find(GameState.current_arc)
	if idx >= 0 and idx + 1 < ARC_ORDER.size():
		return ARC_ORDER[idx + 1]
	return ""

## Gegner-Definition: erst im Arc suchen, dann in der globalen Gegner-Datei.
func get_enemy(id: String) -> Dictionary:
	# Immer eine Kopie zurückgeben – der Kampf verändert kp/alive, das darf
	# nicht in die geladenen Arc-Daten zurückschlagen (sonst wäre ein Boss
	# beim zweiten Versuch schon "besiegt").
	if current.has("enemies") and current["enemies"].has(id):
		return current["enemies"][id].duplicate(true)
	return EnemyDB.get_enemy(id)
