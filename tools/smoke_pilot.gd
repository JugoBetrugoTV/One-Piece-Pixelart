extends Node
## ============================================================================
## smoke_pilot.gd – Automatisierter Headless-Rauchtest (Entwickler-Werkzeug).
##
## Startet KEIN echtes Gameplay-UI für den Spieler, sondern fährt die Systeme
## programmatisch durch und prüft die typischen Godot-Stolperfallen:
##   - Autoloads erreichbar
##   - Map-Aufbau (TileMapLayer) für beide Maps
##   - TileSet-Kollisionsschicht vorhanden
##   - Speichern/Laden ohne Crash
##   - Gegner-Daten werden durch einen Kampf nicht dauerhaft verändert
##   - Kampf läuft bis "Sieg" durch (UI-Aufbau inkl. prozeduraler Sprites)
##   - Dialog mit eingebetteter Aktion (Item erhalten) läuft bis zum Ende
##
## Start:  godot --headless res://tools/SmokePilot.tscn
## Exit-Code = Anzahl fehlgeschlagener Prüfungen (0 = alles ok).
## NICHT Teil des Spiels – nur für Tests.
## ============================================================================

var _failures := 0
var _battle_result := {}
var _dlg_done := false

func _ready() -> void:
	await _run()
	print("\n==== SMOKE-TEST FERTIG: %d Fehler ====" % _failures)
	get_tree().quit(_failures)

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  : ", msg)
	else:
		_failures += 1
		printerr("  FAIL: ", msg)

func _run() -> void:
	# Einen Frame warten, bis der Szenenbaum fertig aufgebaut ist (sonst ist
	# root "busy setting up children" und add_child schlägt fehl).
	await get_tree().process_frame

	# --- Autoloads erreichbar -------------------------------------------------
	_check(GameState != null and ArcManager != null and BattleManager != null
		and DialogueManager != null and QuestManager != null and SaveManager != null,
		"Alle Autoloads erreichbar")

	# --- Datenebene -----------------------------------------------------------
	GameState.new_game()
	_check(GameState.party.size() == 1, "Neues Spiel: Startparty = 1")
	var arc: Dictionary = ArcManager.load_arc("romance_dawn")
	_check(not arc.is_empty(), "Arc romance_dawn geladen")
	_check(ArcManager.arc_exists("orange_town"), "orange_town vorhanden")
	_check(not ArcManager.arc_exists("syrup_village"), "syrup_village (noch) Platzhalter")

	# --- GameManager + Weltaufbau --------------------------------------------
	var gm := preload("res://scenes/main/Main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(gm)
	await get_tree().process_frame
	await get_tree().process_frame

	_check(gm._tileset != null and gm._tileset.get_physics_layers_count() == 1,
		"TileSet mit 1 Physik-Layer aufgebaut")

	gm._enter_overworld("windmuehlen_dorf", null)
	await get_tree().process_frame
	_check(gm._player != null, "Spieler erzeugt")
	_check(gm._npcs.size() == 2, "Dorf: 2 NPCs platziert")
	_check(gm._player.current_tile() == Vector2i(7, 8), "Spieler auf Spawn-Tile (7,8)")

	# Map-Wechsel zur zweiten Map (Dialog/Kampf nach Szenenwechsel stabil?)
	gm._load_map("hafen", null)
	await get_tree().process_frame
	_check(gm._npcs.size() == 2, "Hafen: 2 NPCs nach Map-Wechsel")
	var hafen: Dictionary = ArcManager.get_map("hafen")
	_check(hafen.has("encounter"), "Hafen hat Zufallskampf-Konfiguration")

	# --- Speichern / Laden ----------------------------------------------------
	GameState.gold = 123
	GameState.player_tile = Vector2i(5, 6)
	_check(SaveManager.save_game(), "Speichern erfolgreich")
	GameState.gold = 0
	_check(SaveManager.load_game(), "Laden erfolgreich")
	_check(GameState.gold == 123, "Geladenes Gold korrekt (123)")
	_check(GameState.player_tile == Vector2i(5, 6), "Geladene Position korrekt")

	# --- Gegner-Daten dürfen sich nach Kampf NICHT verändern ------------------
	var e_a: Dictionary = ArcManager.get_enemy("rivax")
	var orig_kp := int(e_a.get("max_kp"))
	e_a["kp"] = 1
	e_a["alive"] = false
	var e_b: Dictionary = ArcManager.get_enemy("rivax")
	_check(int(e_b.get("max_kp")) == orig_kp and not e_b.has("alive"),
		"Gegner-Daten sind unveraendert (frische Kopie pro Kampf)")

	# --- Kampf durchspielen bis Sieg -----------------------------------------
	BattleManager.battle_ended.connect(func(r): _battle_result = r)
	BattleManager.start(["streuner_hund"], false)
	_check(BattleManager.active, "Kampf gestartet")
	_check(BattleManager._enemies.size() == 1, "1 Gegner im Kampf")
	# Sofort alle Gegner "besiegen" -> beim ersten Zug greift die Sieg-Logik.
	for e in BattleManager._enemies:
		e["alive"] = false
		e["kp"] = 0
	await _pump_until(func(): return not _battle_result.is_empty(), 120)
	_check(_battle_result.get("outcome", "") == "win", "Kampf endet mit Sieg")
	_check(not BattleManager.active, "Kampf sauber beendet")

	# --- Dialog mit Aktion (Item erhalten) -----------------------------------
	DialogueManager.dialogue_finished.connect(func(_r): _dlg_done = true)
	var before := int(GameState.inventory.get("reis_ball", 0))
	DialogueManager.start([
		{ "speaker": "Test", "text": "Hier, nimm das.",
		  "action": { "type": "give_item", "id": "reis_ball", "count": 5 } },
		{ "speaker": "Test", "text": "Tschüss." }
	])
	await _pump_until(func(): return _dlg_done, 120)
	_check(_dlg_done, "Dialog bis zum Ende durchlaufen")
	_check(int(GameState.inventory.get("reis_ball", 0)) == before + 5,
		"Dialog-Aktion give_item ausgefuehrt (+5 Reisball)")

func _pump_until(cond: Callable, max_frames: int) -> void:
	for i in max_frames:
		if cond.call():
			return
		Input.action_press("interact")
		await get_tree().process_frame
		Input.action_release("interact")
		await get_tree().process_frame
