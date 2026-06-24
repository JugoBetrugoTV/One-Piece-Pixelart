extends Node2D
## ============================================================================
## game_manager.gd – Hauptsteuerung (Root-Script der Main-Szene).
##
## Verantwortlich für:
##  - Startmenü (Neues Spiel / Laden / Beenden)
##  - Aufbau der Spielwelt: TileMapLayer aus Map-Daten + Kollision
##  - Platzieren von Spieler und NPCs
##  - Interaktion mit NPCs (löst Dialoge aus)
##  - Map-Übergänge ("exits") und Zufallskämpfe ("encounter")
##  - Reaktion auf Dialog-/Kampf-Ergebnisse (Kampf starten, Arc-Wechsel)
##  - Pausenmenü mit Party-/Questübersicht und Speichern/Laden
##
## Die Spielwelt wird komplett im Code aufgebaut, damit das Projekt robust
## bleibt und keine fehleranfälligen Szenendateien von Hand gepflegt werden
## müssen.
## ============================================================================

const TILE := 16
const PlayerScene := preload("res://scenes/player/Player.tscn")
const NpcScene := preload("res://scenes/npc/NPC.tscn")

enum Mode { MENU, OVERWORLD, PAUSED }
var mode: int = Mode.MENU

var _world: Node2D            # enthält TileMapLayer(s) + NPCs
var _player: CharacterBody2D
var _npcs: Array = []
var _tileset: TileSet
var _map_pixel_size: Vector2 = Vector2.ZERO

# UI-Overlays
var _ui: CanvasLayer
var _menu_root: Control
var _pause_root: Control
var _toast: Label

# Zwischenspeicher für verzögerte Aktionen nach einem Kampf.
var _pending_win_dialogue: String = ""

func _ready() -> void:
	_tileset = _build_tileset()
	_world = Node2D.new()
	add_child(_world)
	_build_ui()

	# Auf die Ergebnisse der Manager reagieren.
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	BattleManager.battle_ended.connect(_on_battle_ended)

	_show_main_menu()

# ----------------------------------------------------------------------------
# TileSet im Code aufbauen (Atlas + Kollisionsschicht)
# ----------------------------------------------------------------------------
func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer(0)

	var src := TileSetAtlasSource.new()
	src.texture = PlaceholderArt.tile_atlas()
	src.texture_region_size = Vector2i(TILE, TILE)

	for i in PlaceholderArt.TILE_ORDER.size():
		var coord := Vector2i(i, 0)
		src.create_tile(coord)
		var tname: String = PlaceholderArt.TILE_ORDER[i]
		if PlaceholderArt.SOLID_TILES.has(tname):
			var td: TileData = src.get_tile_data(coord, 0)
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
			]))
	ts.add_source(src, 0)
	return ts

# Atlas-Spalte für einen Tile-Namen.
func _atlas_coord(tname: String) -> Vector2i:
	var idx := PlaceholderArt.TILE_ORDER.find(tname)
	return Vector2i(max(0, idx), 0)

# ----------------------------------------------------------------------------
# Hauptmenü
# ----------------------------------------------------------------------------
func _show_main_menu() -> void:
	mode = Mode.MENU
	if _player:
		_player.controllable = false
	_clear_world()
	_menu_root.visible = true
	_pause_root.visible = false
	_build_menu_buttons()

var _menu_index := 0
var _menu_items: Array = []

func _build_menu_buttons() -> void:
	_menu_items = ["Neues Spiel"]
	if SaveManager.has_save():
		_menu_items.append("Spiel laden")
	_menu_items.append("Beenden")
	_menu_index = 0
	_render_menu()

func _render_menu() -> void:
	for c in _menu_root.get_children():
		if c.name != "Title" and c.name != "Sub":
			c.queue_free()
	var y := 150
	for i in _menu_items.size():
		var lbl := Label.new()
		lbl.text = ("> " if i == _menu_index else "   ") + _menu_items[i]
		lbl.add_theme_color_override("font_color",
			Color("ffd35e") if i == _menu_index else Color("ffffff"))
		lbl.position = Vector2(260, y)
		_menu_root.add_child(lbl)
		y += 28

func _menu_input() -> void:
	if Input.is_action_just_pressed("move_up"):
		_menu_index = (_menu_index - 1 + _menu_items.size()) % _menu_items.size()
		_render_menu()
	elif Input.is_action_just_pressed("move_down"):
		_menu_index = (_menu_index + 1) % _menu_items.size()
		_render_menu()
	elif Input.is_action_just_pressed("interact"):
		match _menu_items[_menu_index]:
			"Neues Spiel": _start_new_game()
			"Spiel laden": _load_game()
			"Beenden": get_tree().quit()

# ----------------------------------------------------------------------------
# Spiel starten / laden
# ----------------------------------------------------------------------------
func _start_new_game() -> void:
	GameState.new_game()
	ArcManager.load_arc(GameState.current_arc)
	var start_map := str(ArcManager.current.get("start_map", ""))
	_enter_overworld(start_map, null)
	_play_arc_intro()

func _load_game() -> void:
	if not SaveManager.load_game():
		_show_toast("Kein Spielstand gefunden.")
		return
	ArcManager.load_arc(GameState.current_arc)
	_enter_overworld(GameState.current_map, GameState.player_tile)

func _enter_overworld(map_id: String, spawn: Variant) -> void:
	_menu_root.visible = false
	_pause_root.visible = false
	mode = Mode.OVERWORLD
	_load_map(map_id, spawn)

func _play_arc_intro() -> void:
	var intro := str(ArcManager.current.get("intro", ""))
	var title := str(ArcManager.current.get("title", ""))
	if intro != "":
		DialogueManager.start([
			{"speaker": "✶ " + title, "text": intro}
		])

# ----------------------------------------------------------------------------
# Map aufbauen
# ----------------------------------------------------------------------------
func _load_map(map_id: String, spawn: Variant) -> void:
	var mdef := ArcManager.get_map(map_id)
	if mdef.is_empty():
		_show_toast("Map fehlt: " + map_id)
		return
	GameState.current_map = map_id
	_clear_world()

	var w := int(mdef.get("w", 20))
	var h := int(mdef.get("h", 15))
	_map_pixel_size = Vector2(w * TILE, h * TILE)
	var legend: Dictionary = mdef.get("legend", {})

	# Boden-Layer (mit Kollision) und optionaler Deko-Layer darüber.
	var ground := _make_layer("Ground", true)
	_fill_layer(ground, mdef.get("ground", []), legend)
	_world.add_child(ground)

	if mdef.has("over"):
		var over := _make_layer("Over", false)
		over.z_index = 5
		_fill_layer(over, mdef.get("over", []), legend)
		_world.add_child(over)

	# NPCs platzieren.
	_npcs.clear()
	for nd in mdef.get("npcs", []):
		var npc := NpcScene.instantiate()
		_world.add_child(npc)
		npc.setup(nd)
		_npcs.append(npc)

	# Spieler erzeugen oder neu positionieren.
	if _player == null:
		_player = PlayerScene.instantiate()
		add_child(_player)
		_player.tile_changed.connect(_on_player_tile_changed)
	var spawn_tile: Vector2i
	if spawn is Vector2i:
		spawn_tile = spawn
	else:
		var s: Array = mdef.get("spawn", [w / 2, h / 2])
		spawn_tile = Vector2i(int(s[0]), int(s[1]))
	_player.place_on_tile(spawn_tile)
	_player.controllable = true

	_apply_camera_limits()

func _make_layer(lname: String, collision: bool) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = lname
	layer.tile_set = _tileset
	layer.collision_enabled = collision
	return layer

func _fill_layer(layer: TileMapLayer, rows: Array, legend: Dictionary) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if not legend.has(ch):
				continue
			var tname := str(legend[ch])
			if tname == "" or tname == ".":
				continue
			layer.set_cell(Vector2i(x, y), 0, _atlas_coord(tname))

func _apply_camera_limits() -> void:
	var cam: Camera2D = _player.get_node_or_null("Camera2D")
	if cam:
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = int(_map_pixel_size.x)
		cam.limit_bottom = int(_map_pixel_size.y)
		cam.make_current()

func _clear_world() -> void:
	for c in _world.get_children():
		c.queue_free()
	_npcs.clear()

# ----------------------------------------------------------------------------
# Spieler-Bewegung -> Exits & Zufallskämpfe
# ----------------------------------------------------------------------------
func _on_player_tile_changed(t: Vector2i) -> void:
	GameState.player_tile = t
	var mdef := ArcManager.get_map(GameState.current_map)

	# Map-Übergänge prüfen.
	for ex in mdef.get("exits", []):
		if int(ex.get("x", -1)) == t.x and int(ex.get("y", -1)) == t.y:
			_show_toast("→ " + str(ex.get("to", "")))
			_load_map(str(ex.get("to", "")), Vector2i(int(ex.get("tx", 1)), int(ex.get("ty", 1))))
			return

	# Zufallskampf prüfen.
	if mdef.has("encounter") and mode == Mode.OVERWORLD:
		var enc: Dictionary = mdef["encounter"]
		if randf() < float(enc.get("rate", 0.0)):
			var pool: Array = enc.get("pool", [])
			if not pool.is_empty():
				var n := randi_range(1, int(enc.get("max", 2)))
				var group: Array = []
				for i in n:
					group.append(pool[randi() % pool.size()])
				_start_battle(group, false, "")

# ----------------------------------------------------------------------------
# Eingabe pro Frame
# ----------------------------------------------------------------------------
func _process(_dt: float) -> void:
	match mode:
		Mode.MENU:
			_menu_input()
		Mode.OVERWORLD:
			if DialogueManager.active or BattleManager.active:
				return
			if Input.is_action_just_pressed("interact"):
				_try_interact()
			elif Input.is_action_just_pressed("menu"):
				_open_pause()
		Mode.PAUSED:
			_pause_input()

func _try_interact() -> void:
	var ft := _player.front_tile()
	for npc in _npcs:
		if npc.tile() == ft:
			var dlg_id := npc.dialogue_id()
			var lines := ArcManager.get_dialogue(dlg_id)
			if lines.is_empty():
				lines = [{"speaker": npc.data.get("name", "?"), "text": "..."}]
			DialogueManager.start(lines)
			return

# ----------------------------------------------------------------------------
# Reaktion auf Dialog-Ende
# ----------------------------------------------------------------------------
func _on_dialogue_finished(result: Dictionary) -> void:
	if result.has("start_battle") and not result["start_battle"].is_empty():
		_pending_win_dialogue = str(result.get("win_dialogue", ""))
		_start_battle(result["start_battle"], bool(result.get("is_boss", false)), _pending_win_dialogue)
		return
	if result.get("next_arc", false):
		_advance_to_next_arc()

func _start_battle(group: Array, is_boss: bool, win_dialogue: String) -> void:
	_pending_win_dialogue = win_dialogue
	if _player:
		_player.controllable = false
	BattleManager.start(group, is_boss)

func _on_battle_ended(result: Dictionary) -> void:
	if _player:
		_player.controllable = true
	match str(result.get("outcome", "")):
		"lose":
			_show_toast("Game Over")
			await get_tree().create_timer(1.0).timeout
			_show_main_menu()
		_:
			# Sieg oder Flucht -> evtl. Anschluss-Dialog (z.B. nach Boss).
			if _pending_win_dialogue != "":
				var lines := ArcManager.get_dialogue(_pending_win_dialogue)
				_pending_win_dialogue = ""
				if not lines.is_empty():
					DialogueManager.start(lines)

# ----------------------------------------------------------------------------
# Arc-Übergang
# ----------------------------------------------------------------------------
func _advance_to_next_arc() -> void:
	var next_id := ArcManager.next_arc_id()
	if next_id == "":
		DialogueManager.start([{"speaker": "Ende", "text": "Das Abenteuer geht weiter ... (Demo-Ende)"}])
		return
	if not ArcManager.arc_exists(next_id):
		# Platzhalter, solange der Arc noch nicht als JSON existiert.
		DialogueManager.start([
			{"speaker": "Nächster Arc", "text": "Der Arc '%s' ist noch ein Platzhalter. Lege dafür einfach data/arcs/%s.json an!" % [next_id, next_id]}
		])
		return
	ArcManager.load_arc(next_id)
	_enter_overworld(str(ArcManager.current.get("start_map", "")), null)
	_play_arc_intro()

# ----------------------------------------------------------------------------
# Pausenmenü (Party / Quests / Speichern)
# ----------------------------------------------------------------------------
func _open_pause() -> void:
	mode = Mode.PAUSED
	if _player:
		_player.controllable = false
	_pause_root.visible = true
	_render_pause()

func _close_pause() -> void:
	mode = Mode.OVERWORLD
	if _player:
		_player.controllable = true
	_pause_root.visible = false

var _pause_index := 0
var _pause_items := ["Weiter", "Speichern", "Laden", "Hauptmenü"]

func _render_pause() -> void:
	for c in _pause_root.get_children():
		if c.name != "PBG":
			c.queue_free()

	# Linke Spalte: Crew + Quests.
	var lines: Array = []
	lines.append("=== CREW ===")
	for m in GameState.party:
		lines.append("%s (%s) Lv.%d  KP %d/%d  TP %d/%d" % [
			m.name, m.role, int(m.level), int(m.kp), int(m.max_kp), int(m.tp), int(m.max_tp)])
	lines.append("")
	lines.append("Gold: %d" % GameState.gold)
	lines.append("")
	lines.append("=== QUESTS ===")
	var qlog := QuestManager.active_log()
	if qlog.is_empty():
		lines.append("(keine aktiven Quests)")
	for q in qlog:
		var status := "✔" if q.done else "•"
		lines.append("%s %s – %s" % [status, q.name, q.hint])
	var info := Label.new()
	info.text = "\n".join(lines)
	info.position = Vector2(30, 24)
	_pause_root.add_child(info)

	# Rechte Spalte: navigierbares Menü.
	var y := 24
	for i in _pause_items.size():
		var lbl := Label.new()
		lbl.text = ("> " if i == _pause_index else "   ") + _pause_items[i]
		lbl.add_theme_color_override("font_color",
			Color("ffd35e") if i == _pause_index else Color("ffffff"))
		lbl.position = Vector2(440, y)
		_pause_root.add_child(lbl)
		y += 26

func _pause_input() -> void:
	if Input.is_action_just_pressed("menu") or Input.is_action_just_pressed("cancel"):
		_close_pause()
	elif Input.is_action_just_pressed("move_up"):
		_pause_index = (_pause_index - 1 + _pause_items.size()) % _pause_items.size()
		_render_pause()
	elif Input.is_action_just_pressed("move_down"):
		_pause_index = (_pause_index + 1) % _pause_items.size()
		_render_pause()
	elif Input.is_action_just_pressed("interact"):
		match _pause_items[_pause_index]:
			"Weiter":
				_close_pause()
			"Speichern":
				if SaveManager.save_game():
					_show_toast("Gespeichert.")
			"Laden":
				if SaveManager.load_game():
					ArcManager.load_arc(GameState.current_arc)
					_close_pause()
					_load_map(GameState.current_map, GameState.player_tile)
					_show_toast("Geladen.")
				else:
					_show_toast("Kein Spielstand.")
			"Hauptmenü":
				_close_pause()
				_show_main_menu()

# ----------------------------------------------------------------------------
# UI-Grundgerüst & Toast-Meldungen
# ----------------------------------------------------------------------------
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)

	# Hauptmenü
	_menu_root = Control.new()
	_menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(_menu_root)
	var mbg := ColorRect.new()
	mbg.name = "MBG"
	mbg.color = Color("0d0f1a")
	mbg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_root.add_child(mbg)
	var title := Label.new()
	title.name = "Title"
	title.text = "⚓ GRAND VOYAGE"
	title.position = Vector2(200, 80)
	title.add_theme_color_override("font_color", Color("ffd35e"))
	title.add_theme_font_size_override("font_size", 28)
	_menu_root.add_child(title)
	var sub := Label.new()
	sub.name = "Sub"
	sub.text = "Ein One-Piece-inspiriertes Pixel-RPG · Fan-Projekt"
	sub.position = Vector2(170, 120)
	sub.add_theme_color_override("font_color", Color("8b90a8"))
	_menu_root.add_child(sub)

	# Pausen-Overlay
	_pause_root = Control.new()
	_pause_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_root.visible = false
	_ui.add_child(_pause_root)
	var pbg := ColorRect.new()
	pbg.name = "PBG"
	pbg.color = Color(0.05, 0.06, 0.1, 0.92)
	pbg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_root.add_child(pbg)

	# Toast (kurze Hinweise)
	_toast = Label.new()
	_toast.position = Vector2(16, 8)
	_toast.add_theme_color_override("font_color", Color("ffd35e"))
	_ui.add_child(_toast)

func _show_toast(text: String) -> void:
	_toast.text = text
	var tween := create_tween()
	_toast.modulate.a = 1.0
	tween.tween_interval(1.4)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
