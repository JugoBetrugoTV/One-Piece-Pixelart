extends Node
## ============================================================================
## GameState (Autoload-Singleton)
## ----------------------------------------------------------------------------
## Zentraler, global erreichbarer Spielzustand. Hier liegt ALLES, was in einen
## Spielstand gehört: Party, Inventar, Gold, Story-Flags, Questfortschritt,
## aktueller Arc und aktuelle Map.
##
## Andere Systeme greifen über `GameState.xxx` darauf zu. Der SaveManager
## serialisiert genau diese Felder.
## ============================================================================

# --- Laufender Spielzustand -------------------------------------------------
var party: Array = []            # Liste aus Crew-Mitglied-Dictionaries
var gold: int = 50
var inventory: Dictionary = {}   # item_id -> Anzahl
var flags: Dictionary = {}       # beliebige Story-Schalter, z.B. {"makino_gesprochen": true}
var quests: Dictionary = {}      # quest_id -> {"state": "aktiv"/"erledigt", "step": int}
var current_arc: String = "romance_dawn"
var current_map: String = ""     # wird beim Laden des Arcs gesetzt
var player_tile: Vector2i = Vector2i.ZERO  # letzte Spielerposition (für Saves)

# Signal, damit die UI (z.B. Questlog) auf Änderungen reagieren kann.
signal state_changed

## ----------------------------------------------------------------------------
## Crew-Vorlagen: Basiswerte der spielbaren Charaktere.
## Eigene Namen – bewusst KEINE originalen One-Piece-Namen.
## Jeder hat einen eigenen Skill mit eigenem Charakterzug.
## ----------------------------------------------------------------------------
const CREW_TEMPLATES := {
	"kapu": {
		"id": "kapu", "name": "Kapu",            # der Kapitän mit dem Strohhut
		"role": "Kapitän",
		"colors": {"skin": "f0c090", "hair": "1a1a1a", "shirt": "d94f4f", "pants": "2f5fb0", "accent": "e8c86a"},
		"base": {"max_kp": 40, "max_tp": 10, "atk": 12, "def": 6, "spd": 9},
		"skills": [
			{"id": "gummi_hieb", "name": "Gummi-Hieb", "tp": 3, "power": 1.8, "all": false,
			 "text": "Ein weit ausholender, federnder Schlag."}
		]
	},
	"zelos": {
		"id": "zelos", "name": "Zelos",          # der Schwertkämpfer
		"role": "Schwertkämpfer",
		"colors": {"skin": "e8b888", "hair": "3a7d4a", "shirt": "2f6f5f", "pants": "303040", "accent": ""},
		"base": {"max_kp": 50, "max_tp": 8, "atk": 15, "def": 8, "spd": 7},
		"skills": [
			{"id": "drei_klingen", "name": "Drei-Klingen-Sturm", "tp": 4, "power": 2.0, "all": false,
			 "text": "Ein wirbelnder Mehrfachhieb."}
		]
	},
	"nadia": {
		"id": "nadia", "name": "Nadia",          # die Navigatorin
		"role": "Navigatorin",
		"colors": {"skin": "f0c8a0", "hair": "e08a2a", "shirt": "f0a8c0", "pants": "5a4a8a", "accent": ""},
		"base": {"max_kp": 32, "max_tp": 14, "atk": 9, "def": 5, "spd": 12},
		"skills": [
			{"id": "wetterschlag", "name": "Wetterschlag", "tp": 4, "power": 1.6, "all": true,
			 "text": "Ein elektrischer Schlag, der alle Gegner trifft."}
		]
	}
}

func _ready() -> void:
	_setup_input()

## ----------------------------------------------------------------------------
## Eingabe-Aktionen zur Laufzeit registrieren.
## Vorteil: wir müssen keine fehleranfälligen InputEvent-Objekte in
## project.godot serialisieren – alles steht klar lesbar hier im Code.
## ----------------------------------------------------------------------------
func _setup_input() -> void:
	_bind("move_up",    [KEY_W, KEY_UP])
	_bind("move_down",  [KEY_S, KEY_DOWN])
	_bind("move_left",  [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("interact",   [KEY_E, KEY_ENTER, KEY_SPACE])
	_bind("cancel",     [KEY_ESCAPE, KEY_BACKSPACE])
	_bind("menu",       [KEY_Q])

func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

## ----------------------------------------------------------------------------
## Neues Spiel: setzt alle Felder auf den Anfangszustand zurück.
## ----------------------------------------------------------------------------
func new_game() -> void:
	party = [make_member("kapu")]   # man startet allein als junger Pirat
	gold = 50
	inventory = {"reis_ball": 3, "fleisch_spiess": 1}
	flags = {}
	quests = {}
	current_arc = "romance_dawn"
	current_map = ""
	player_tile = Vector2i.ZERO
	emit_signal("state_changed")

## Erzeugt aus einer Vorlage ein konkretes Crew-Mitglied mit vollen Werten.
func make_member(id: String) -> Dictionary:
	var t: Dictionary = CREW_TEMPLATES[id]
	var m := {
		"id": t.id, "name": t.name, "role": t.role,
		"colors": t.colors.duplicate(),
		"level": 1, "exp": 0,
		"max_kp": t.base.max_kp, "kp": t.base.max_kp,
		"max_tp": t.base.max_tp, "tp": t.base.max_tp,
		"atk": t.base.atk, "def": t.base.def, "spd": t.base.spd,
		"skills": t.skills.duplicate(true),
		"weapon": null, "armor": null
	}
	return m

## Fügt ein Crew-Mitglied hinzu (wenn nicht schon dabei).
func recruit(id: String) -> bool:
	for m in party:
		if m.id == id:
			return false
	party.append(make_member(id))
	emit_signal("state_changed")
	return true

# --- Inventar-Helfer --------------------------------------------------------
func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + count
	emit_signal("state_changed")

func remove_item(item_id: String, count: int = 1) -> void:
	if not inventory.has(item_id):
		return
	inventory[item_id] = int(inventory[item_id]) - count
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	emit_signal("state_changed")

func has_item(item_id: String) -> bool:
	return int(inventory.get(item_id, 0)) > 0

# --- Flags ------------------------------------------------------------------
func set_flag(name: String, value: bool = true) -> void:
	flags[name] = value
	emit_signal("state_changed")

func get_flag(name: String) -> bool:
	return bool(flags.get(name, false))

## Berechnet den effektiven Angriff/Verteidigung eines Mitglieds inkl.
## Ausrüstung. Wird im Kampf genutzt.
func eff_atk(m: Dictionary) -> int:
	var bonus := 0
	if m.weapon:
		bonus = int(ItemHelper.get_item(m.weapon).get("atk", 0))
	return int(m.atk) + bonus

func eff_def(m: Dictionary) -> int:
	var bonus := 0
	if m.armor:
		bonus = int(ItemHelper.get_item(m.armor).get("def", 0))
	return int(m.def) + bonus
