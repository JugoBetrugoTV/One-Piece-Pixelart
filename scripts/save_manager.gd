extends Node
## ============================================================================
## SaveManager (Autoload)
## ----------------------------------------------------------------------------
## Speichert/lädt den kompletten Spielzustand als JSON unter user://.
## Unter Windows liegt das z.B. in %APPDATA%/Godot/app_userdata/Grand Voyage/.
##
## Gespeichert werden alle Felder aus GameState: Party, Level, Inventar, Gold,
## Quests, Flags, aktueller Arc, aktuelle Map und Spielerposition.
## ============================================================================

const SAVE_PATH := "user://savegame.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Schreibt den aktuellen GameState in die Save-Datei.
## `player_tile` wird vorher von der Spielwelt aktualisiert.
func save_game() -> bool:
	var data := {
		"version": 1,
		"party": GameState.party,
		"gold": GameState.gold,
		"inventory": GameState.inventory,
		"flags": GameState.flags,
		"quests": GameState.quests,
		"current_arc": GameState.current_arc,
		"current_map": GameState.current_map,
		"player_tile": [GameState.player_tile.x, GameState.player_tile.y],
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Konnte Save-Datei nicht schreiben.")
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true

## Lädt die Save-Datei zurück in den GameState.
func load_game() -> bool:
	if not has_save():
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save-Datei beschädigt.")
		return false
	GameState.party = parsed.get("party", [])
	GameState.gold = int(parsed.get("gold", 0))
	GameState.inventory = parsed.get("inventory", {})
	GameState.flags = parsed.get("flags", {})
	GameState.quests = parsed.get("quests", {})
	GameState.current_arc = str(parsed.get("current_arc", "romance_dawn"))
	GameState.current_map = str(parsed.get("current_map", ""))
	var pt: Array = parsed.get("player_tile", [0, 0])
	GameState.player_tile = Vector2i(int(pt[0]), int(pt[1]))
	GameState.emit_signal("state_changed")
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
