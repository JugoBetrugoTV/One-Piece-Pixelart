extends Node
## ============================================================================
## BattleManager (Autoload)
## ----------------------------------------------------------------------------
## Rundenbasiertes RPG-Kampfsystem (bewusst gewählt: stabiler & einfacher als
## ein Action-Kampf).
##
## Ablauf:
##  - Zu Beginn jeder Runde werden alle lebenden Kämpfer nach Tempo (spd)
##    sortiert.
##  - Ist ein Party-Mitglied am Zug, öffnet sich ein Befehlsmenü
##    (Angriff / Spezial / Item / Flucht).
##  - Gegner handeln automatisch (einfache KI).
##  - Sieg => EXP + Gold + mögliche Level-Ups. Niederlage => Game Over zurück
##    ins Hauptmenü.
##
## Aufruf:  BattleManager.start(["berg_bandit","berg_bandit"], false)
## Ergebnis: Signal `battle_ended(result)` mit result.outcome = "win"/"lose"/"flee".
## ============================================================================

signal battle_ended(result: Dictionary)

var active: bool = false

# Kämpfer-Listen. Verbündete referenzieren direkt die GameState-Member-Dicts,
# damit KP/TP nach dem Kampf erhalten bleiben.
var _allies: Array = []
var _enemies: Array = []
var _order: Array = []
var _turn_ptr: int = 0
var _is_boss: bool = false

# Zustands-Maschine
var _state: String = ""          # "message" | "choose" | "enemy" | "done"
var _menu_mode: String = "root"  # "root" | "skill" | "item" | "target_enemy" | "target_ally"
var _menu_index: int = 0
var _menu_options: Array = []
var _current: Dictionary = {}    # aktuell handelndes Party-Mitglied
var _msg_timer: float = 0.0
var _pending_outcome: String = ""

# UI
var _layer: CanvasLayer
var _enemy_row: HBoxContainer
var _party_panel: VBoxContainer
var _menu_panel: VBoxContainer
var _msg_lbl: Label

# ----------------------------------------------------------------------------
# Fortschritt / Level (auch von QuestManager genutzt)
# ----------------------------------------------------------------------------
func exp_needed(level: int) -> int:
	return level * level * 8 + 10

## Vergibt EXP an ein Mitglied und löst Level-Ups aus. Gibt Meldungen zurück.
func grant_exp(m: Dictionary, amount: int) -> Array:
	var msgs: Array = []
	m.exp = int(m.exp) + amount
	while int(m.exp) >= exp_needed(int(m.level)):
		m.exp = int(m.exp) - exp_needed(int(m.level))
		m.level = int(m.level) + 1
		m.max_kp = int(m.max_kp) + randi_range(4, 7)
		m.max_tp = int(m.max_tp) + 1
		m.atk = int(m.atk) + 2
		m.def = int(m.def) + 1
		m.spd = int(m.spd) + 1
		m.kp = m.max_kp
		msgs.append("%s erreicht Level %d!" % [m.name, m.level])
	return msgs

# ----------------------------------------------------------------------------
# Start / Aufbau
# ----------------------------------------------------------------------------
func _ready() -> void:
	_build_ui()

func start(group: Array, is_boss: bool = false) -> void:
	_is_boss = is_boss
	_allies = []
	for m in GameState.party:
		if int(m.kp) <= 0:
			m.kp = max(1, int(m.max_kp) / 2)  # angeschlagene Mitglieder stehen wieder
		_allies.append(m)

	_enemies = []
	for eid in group:
		var def := ArcManager.get_enemy(str(eid))
		if def.is_empty():
			continue
		def["kp"] = int(def.get("max_kp", 10))
		def["alive"] = true
		_enemies.append(def)

	if _enemies.is_empty():
		# Keine gültigen Gegner -> sofort "gewonnen", damit das Spiel nicht hängt.
		_emit_end("win")
		return

	active = true
	_layer.visible = true
	_rebuild_visuals()
	_msg("Ein Kampf beginnt!", 1.0)
	_pending_after_message = func(): _begin_round()

# Wird nach Ablauf einer Nachricht ausgeführt.
var _pending_after_message: Callable = Callable()

func _begin_round() -> void:
	# Reihenfolge nach Tempo, nur lebende Kämpfer.
	_order = []
	for a in _allies:
		if int(a.kp) > 0:
			_order.append({"side": "ally", "ref": a})
	for e in _enemies:
		if e.alive:
			_order.append({"side": "enemy", "ref": e})
	_order.sort_custom(func(x, y): return int(x.ref.spd) > int(y.ref.spd))
	_turn_ptr = 0
	_next_turn()

func _next_turn() -> void:
	if _check_end():
		return
	if _turn_ptr >= _order.size():
		_begin_round()
		return
	var entry: Dictionary = _order[_turn_ptr]
	var ref: Dictionary = entry.ref
	# Tote überspringen.
	var dead: bool = (entry.side == "ally" and int(ref.kp) <= 0) or (entry.side == "enemy" and not ref.alive)
	if dead:
		_turn_ptr += 1
		_next_turn()
		return
	if entry.side == "enemy":
		_enemy_act(ref)
	else:
		_current = ref
		_open_root_menu()

# ----------------------------------------------------------------------------
# Spieler-Befehle
# ----------------------------------------------------------------------------
func _open_root_menu() -> void:
	_state = "choose"
	_menu_mode = "root"
	_menu_index = 0
	_menu_options = ["Angriff", "Spezial", "Item", "Flucht"]
	_msg_lbl.text = "%s ist am Zug." % _current.name
	_refresh_menu()

func _refresh_menu() -> void:
	for c in _menu_panel.get_children():
		c.queue_free()
	for i in _menu_options.size():
		var lbl := Label.new()
		var txt: String = str(_menu_options[i])
		lbl.text = ("> " if i == _menu_index else "  ") + txt
		lbl.add_theme_color_override("font_color",
			Color("ffd35e") if i == _menu_index else Color("ffffff"))
		_menu_panel.add_child(lbl)

func _process(dt: float) -> void:
	if not active:
		return
	match _state:
		"message":
			_msg_timer -= dt
			if _msg_timer <= 0.0 or Input.is_action_just_pressed("interact"):
				_state = "idle"
				if _pending_after_message.is_valid():
					var cb := _pending_after_message
					_pending_after_message = Callable()
					cb.call()
		"choose":
			_handle_menu()

func _handle_menu() -> void:
	if Input.is_action_just_pressed("move_up"):
		_menu_index = (_menu_index - 1 + _menu_options.size()) % _menu_options.size()
		_refresh_menu()
	elif Input.is_action_just_pressed("move_down"):
		_menu_index = (_menu_index + 1) % _menu_options.size()
		_refresh_menu()
	elif Input.is_action_just_pressed("cancel") and _menu_mode != "root":
		_open_root_menu()
	elif Input.is_action_just_pressed("interact"):
		_select_menu()

func _select_menu() -> void:
	match _menu_mode:
		"root":
			match _menu_index:
				0: _begin_target_enemy("attack", {})
				1: _open_skill_menu()
				2: _open_item_menu()
				3: _try_flee()
		"skill":
			var skills: Array = _current.skills
			if _menu_index >= skills.size():
				return
			var sk: Dictionary = skills[_menu_index]
			if int(_current.tp) < int(sk.get("tp", 0)):
				_msg("Nicht genug TP!", 0.8)
				_pending_after_message = func(): _open_root_menu()
				return
			if bool(sk.get("all", false)):
				_do_skill_all(sk)
			else:
				_begin_target_enemy("skill", sk)
		"item":
			_use_item_selected()
		"target_enemy":
			_confirm_enemy_target()
		"target_ally":
			_confirm_ally_target()

func _open_skill_menu() -> void:
	_menu_mode = "skill"
	_menu_index = 0
	_menu_options = []
	for sk in _current.skills:
		_menu_options.append("%s (TP %d)" % [sk.name, int(sk.get("tp", 0))])
	if _menu_options.is_empty():
		_menu_options = ["(keine)"]
	_refresh_menu()

func _open_item_menu() -> void:
	_menu_mode = "item"
	_menu_index = 0
	_menu_options = []
	_item_ids = []
	for id in GameState.inventory:
		var it := ItemHelper.get_item(id)
		if it.get("typ", "") == "heilung":
			_item_ids.append(id)
			_menu_options.append("%s x%d" % [it.get("name", id), int(GameState.inventory[id])])
	if _menu_options.is_empty():
		_menu_options = ["(keine Items)"]
	_refresh_menu()

var _item_ids: Array = []
var _pending_action: String = ""
var _pending_skill: Dictionary = {}

func _begin_target_enemy(action: String, skill: Dictionary) -> void:
	_pending_action = action
	_pending_skill = skill
	_menu_mode = "target_enemy"
	_menu_index = _first_alive_enemy()
	if _menu_index < 0:
		return
	_menu_options = []
	for e in _enemies:
		_menu_options.append(e.name + ("" if e.alive else " (besiegt)"))
	_refresh_menu()

func _first_alive_enemy() -> int:
	for i in _enemies.size():
		if _enemies[i].alive:
			return i
	return -1

func _confirm_enemy_target() -> void:
	if _menu_index < 0 or _menu_index >= _enemies.size():
		return
	var target: Dictionary = _enemies[_menu_index]
	if not target.alive:
		return
	if _pending_action == "attack":
		_do_attack(_current, target)
	elif _pending_action == "skill":
		_do_skill_single(_pending_skill, target)

func _use_item_selected() -> void:
	if _item_ids.is_empty() or _menu_index >= _item_ids.size():
		return
	# Ziel-Mitglied auswählen.
	_menu_mode = "target_ally"
	_pending_item = _item_ids[_menu_index]
	_menu_index = 0
	_menu_options = []
	for a in _allies:
		_menu_options.append("%s (KP %d/%d)" % [a.name, int(a.kp), int(a.max_kp)])
	_refresh_menu()

var _pending_item: String = ""

func _confirm_ally_target() -> void:
	var target: Dictionary = _allies[_menu_index]
	var it := ItemHelper.get_item(_pending_item)
	var heal := int(it.get("heal", 0))
	target.kp = min(int(target.max_kp), int(target.kp) + heal)
	GameState.remove_item(_pending_item, 1)
	_msg("%s benutzt %s. +%d KP." % [_current.name, it.get("name", _pending_item), heal], 0.9)
	_pending_after_message = func(): _end_player_turn()

# ----------------------------------------------------------------------------
# Aktions-Auflösung
# ----------------------------------------------------------------------------
func _do_attack(attacker: Dictionary, target: Dictionary) -> void:
	var dmg := _calc_damage(GameState.eff_atk(attacker), int(target.def), 1.0)
	target.kp = int(target.kp) - dmg
	_msg("%s greift %s an! %d Schaden." % [attacker.name, target.name, dmg], 0.9)
	_after_offense(target)

func _do_skill_single(sk: Dictionary, target: Dictionary) -> void:
	_current.tp = int(_current.tp) - int(sk.get("tp", 0))
	var dmg := _calc_damage(GameState.eff_atk(_current), int(target.def), float(sk.get("power", 1.0)))
	target.kp = int(target.kp) - dmg
	_msg("%s setzt %s ein! %d Schaden." % [_current.name, sk.name, dmg], 1.0)
	_after_offense(target)

func _do_skill_all(sk: Dictionary) -> void:
	_current.tp = int(_current.tp) - int(sk.get("tp", 0))
	var total := 0
	for e in _enemies:
		if e.alive:
			var dmg := _calc_damage(GameState.eff_atk(_current), int(e.def), float(sk.get("power", 1.0)))
			e.kp = int(e.kp) - dmg
			total += dmg
			if int(e.kp) <= 0:
				e.alive = false
	_msg("%s setzt %s gegen alle ein! %d Schaden gesamt." % [_current.name, sk.name, total], 1.1)
	_rebuild_visuals()
	_pending_after_message = func(): _end_player_turn()

func _after_offense(target: Dictionary) -> void:
	if int(target.kp) <= 0:
		target.alive = false
		target.kp = 0
	_rebuild_visuals()
	_pending_after_message = func(): _end_player_turn()

func _end_player_turn() -> void:
	if _check_end():
		return
	_turn_ptr += 1
	_next_turn()

func _calc_damage(atk: int, def: int, power: float) -> int:
	var base := float(atk) * power - float(def) * 0.5
	var variance := randf_range(0.85, 1.15)
	return max(1, int(round(base * variance)))

# ----------------------------------------------------------------------------
# Gegner-KI
# ----------------------------------------------------------------------------
func _enemy_act(e: Dictionary) -> void:
	# Lebendes Party-Mitglied als Ziel wählen.
	var targets: Array = []
	for a in _allies:
		if int(a.kp) > 0:
			targets.append(a)
	if targets.is_empty():
		_check_end()
		return
	var target: Dictionary = targets[randi() % targets.size()]

	# Gelegentlich eine Spezialfähigkeit, sonst normaler Angriff.
	var skills: Array = e.get("skills", [])
	var use_skill := skills.size() > 0 and randf() < 0.3
	var power := 1.0
	var label := "greift an"
	if use_skill:
		var sk: Dictionary = skills[randi() % skills.size()]
		power = float(sk.get("power", 1.0))
		label = "setzt %s ein" % sk.get("name", "eine Technik")

	var dmg := _calc_damage(int(e.atk), GameState.eff_def(target), power)
	target.kp = int(target.kp) - dmg
	if int(target.kp) <= 0:
		target.kp = 0
	_msg("%s %s! %s erleidet %d Schaden." % [e.name, label, target.name, dmg], 0.9)
	_rebuild_visuals()
	_pending_after_message = _after_enemy_turn

## Nach einem Gegnerzug: Kampfende prüfen, sonst nächster Kämpfer.
func _after_enemy_turn() -> void:
	if _check_end():
		return
	_turn_ptr += 1
	_next_turn()

# ----------------------------------------------------------------------------
# Ende / Sieg / Niederlage
# ----------------------------------------------------------------------------
func _check_end() -> bool:
	var allies_alive := false
	for a in _allies:
		if int(a.kp) > 0:
			allies_alive = true
			break
	var enemies_alive := false
	for e in _enemies:
		if e.alive:
			enemies_alive = true
			break
	if not enemies_alive:
		_victory()
		return true
	if not allies_alive:
		_defeat()
		return true
	return false

func _victory() -> void:
	var total_exp := 0
	var total_gold := 0
	for e in _enemies:
		total_exp += int(e.get("exp", 0))
		total_gold += int(e.get("gold", 0))
	GameState.gold += total_gold
	var levelmsgs: Array = []
	for a in _allies:
		if int(a.kp) > 0:
			levelmsgs += grant_exp(a, total_exp)
	var txt := "Sieg! +%d EXP, +%d Gold." % [total_exp, total_gold]
	if not levelmsgs.is_empty():
		txt += "  " + " ".join(levelmsgs)
	_msg(txt, 1.4)
	_pending_after_message = func(): _emit_end("win")

func _defeat() -> void:
	_msg("Die Crew wurde besiegt ...", 1.4)
	_pending_after_message = func(): _emit_end("lose")

func _try_flee() -> void:
	if _is_boss:
		_msg("Vor diesem Gegner kann man nicht fliehen!", 0.9)
		_pending_after_message = func(): _open_root_menu()
		return
	if randf() < 0.6:
		_msg("Flucht gelungen!", 0.9)
		_pending_after_message = func(): _emit_end("flee")
	else:
		_msg("Flucht gescheitert!", 0.9)
		_pending_after_message = func(): _end_player_turn()

func _emit_end(outcome: String) -> void:
	active = false
	_layer.visible = false
	emit_signal("battle_ended", {"outcome": outcome})

# ----------------------------------------------------------------------------
# UI
# ----------------------------------------------------------------------------
func _msg(text: String, seconds: float) -> void:
	_msg_lbl.text = text
	_msg_timer = seconds
	_state = "message"

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 25
	add_child(_layer)

	var bg := ColorRect.new()
	bg.color = Color("141826")
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	_layer.add_child(bg)

	var title := Label.new()
	title.text = "⚔ KAMPF"
	title.position = Vector2(16, 10)
	title.add_theme_color_override("font_color", Color("ffd35e"))
	_layer.add_child(title)

	_enemy_row = HBoxContainer.new()
	_enemy_row.position = Vector2(40, 50)
	_enemy_row.add_theme_constant_override("separation", 24)
	_layer.add_child(_enemy_row)

	_party_panel = VBoxContainer.new()
	_party_panel.position = Vector2(16, 200)
	_layer.add_child(_party_panel)

	_menu_panel = VBoxContainer.new()
	_menu_panel.position = Vector2(420, 200)
	_layer.add_child(_menu_panel)

	_msg_lbl = Label.new()
	_msg_lbl.position = Vector2(16, 170)
	_msg_lbl.add_theme_color_override("font_color", Color("ffffff"))
	_layer.add_child(_msg_lbl)

	_layer.visible = false

## Baut Gegner-Sprites und Statusanzeigen neu auf (nach jeder Aktion).
func _rebuild_visuals() -> void:
	for c in _enemy_row.get_children():
		c.queue_free()
	for e in _enemies:
		var box := VBoxContainer.new()
		var tex := TextureRect.new()
		tex.texture = PlaceholderArt.make_enemy(str(e.get("color", "a83232")))
		tex.custom_minimum_size = Vector2(48, 48)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		tex.modulate = Color(1, 1, 1, 1) if e.alive else Color(0.3, 0.3, 0.3, 0.5)
		box.add_child(tex)
		var lbl := Label.new()
		lbl.text = "%s\nKP %d/%d" % [e.name, max(0, int(e.kp)), int(e.max_kp)]
		box.add_child(lbl)
		_enemy_row.add_child(box)

	for c in _party_panel.get_children():
		c.queue_free()
	for a in _allies:
		var lbl := Label.new()
		lbl.text = "%s  KP %d/%d  TP %d/%d" % [a.name, max(0, int(a.kp)), int(a.max_kp), int(a.tp), int(a.max_tp)]
		lbl.add_theme_color_override("font_color",
			Color("ffffff") if int(a.kp) > 0 else Color("a83232"))
		_party_panel.add_child(lbl)
