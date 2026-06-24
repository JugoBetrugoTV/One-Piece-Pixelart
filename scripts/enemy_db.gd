class_name EnemyDB
extends RefCounted
## ============================================================================
## EnemyDB – globale Gegner-Datenbank aus data/enemies/enemies.json.
## Arc-spezifische Gegner/Bosse stehen direkt in der jeweiligen Arc-JSON und
## haben Vorrang (siehe ArcManager.get_enemy).
##
## Gegner-Schema:
##   { "id","name","max_kp","atk","def","spd","exp","gold",
##     "color" (Hex), "skills"[ {name,power,tp?} ] }
## ============================================================================

static var DB: Dictionary = {}
const PATH := "res://data/enemies/enemies.json"

static func ensure_loaded() -> void:
	if not DB.is_empty():
		return
	if not FileAccess.file_exists(PATH):
		push_warning("enemies.json nicht gefunden.")
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		DB = parsed

static func get_enemy(id: String) -> Dictionary:
	ensure_loaded()
	return DB.get(id, {}).duplicate(true)
