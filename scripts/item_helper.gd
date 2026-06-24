class_name ItemHelper
extends RefCounted
## ============================================================================
## ItemHelper – lädt die Gegenstands-Datenbank aus data/items/items.json
## und stellt sie statisch unter `ItemHelper.DB` bereit.
##
## typ: "heilung" | "waffe" | "ruestung" | "schluessel"
## ============================================================================

static var DB: Dictionary = {}

const PATH := "res://data/items/items.json"

## Stellt sicher, dass die Datenbank geladen ist (lazy load).
static func ensure_loaded() -> void:
	if not DB.is_empty():
		return
	if not FileAccess.file_exists(PATH):
		push_warning("items.json nicht gefunden: " + PATH)
		return
	var text := FileAccess.get_file_as_string(PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		DB = parsed
	else:
		push_error("items.json konnte nicht geparst werden.")

static func get_item(id: String) -> Dictionary:
	ensure_loaded()
	return DB.get(id, {})

static func name_of(id: String) -> String:
	var it := get_item(id)
	return str(it.get("name", id))
