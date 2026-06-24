extends Node
## ============================================================================
## DialogueManager (Autoload)
## ----------------------------------------------------------------------------
## JSON-basiertes Dialogsystem mit Auswahlmöglichkeiten ("choices") und
## eingebetteten Story-Aktionen ("action").
##
## Eine Dialog-Sequenz ist ein Array aus Zeilen-Objekten:
##   {
##     "speaker": "Makina",
##     "text": "Hallo! Pass auf dich auf.",
##     "action": {"type": "start_quest", "id": "rd_main"},     # optional
##     "choices": [                                            # optional
##        {"text": "Klar!",  "goto": 4},
##        {"text": "Nö.",    "goto": 6, "action": {...}}
##     ]
##   }
##
## Unterstützte Aktions-Typen:
##   set_flag {flag,value} · recruit {id} · give_item {id,count}
##   start_quest {id} · advance_quest {id} · heal_party
##   start_battle {group:[..]} / {boss:true}  (verzögert bis Dialogende)
##   next_arc                                  (verzögert bis Dialogende)
##
## Reine UI (Panel + Text + Auswahl) wird hier im Code aufgebaut.
## Am Ende wird `dialogue_finished(result)` ausgesendet; `result` enthält
## verzögerte Anfragen wie {"start_battle": [...]} oder {"next_arc": true},
## die der GameManager nach dem Schließen ausführt.
## ============================================================================

signal dialogue_finished(result: Dictionary)

var active: bool = false

var _lines: Array = []
var _index: int = 0
var _result: Dictionary = {}
var _choosing: bool = false
var _choice_index: int = 0

# UI-Knoten
var _layer: CanvasLayer
var _panel: Panel
var _speaker_lbl: Label
var _text_lbl: RichTextLabel
var _choice_box: VBoxContainer

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 20
	add_child(_layer)

	_panel = Panel.new()
	_panel.anchor_left = 0.0
	_panel.anchor_top = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 12
	_panel.offset_right = -12
	_panel.offset_top = -120
	_panel.offset_bottom = -12
	_layer.add_child(_panel)

	_speaker_lbl = Label.new()
	_speaker_lbl.position = Vector2(14, 8)
	_speaker_lbl.add_theme_color_override("font_color", Color("ffd35e"))
	_panel.add_child(_speaker_lbl)

	_text_lbl = RichTextLabel.new()
	_text_lbl.bbcode_enabled = true
	_text_lbl.fit_content = true
	_text_lbl.scroll_active = false
	_text_lbl.position = Vector2(14, 30)
	_text_lbl.size = Vector2(600, 60)
	_panel.add_child(_text_lbl)

	_choice_box = VBoxContainer.new()
	_choice_box.position = Vector2(360, 8)
	_panel.add_child(_choice_box)

	_layer.visible = false

## Startet eine Dialog-Sequenz.
func start(lines: Array) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	_result = {}
	_choosing = false
	active = true
	_layer.visible = true
	_show_current()

func _show_current() -> void:
	if _index < 0 or _index >= _lines.size():
		_finish()
		return
	var line: Dictionary = _lines[_index]

	# Beim Anzeigen einer Zeile deren Aktion ausführen (sofern vorhanden).
	if line.has("action"):
		_run_action(line["action"])

	_speaker_lbl.text = str(line.get("speaker", ""))
	_text_lbl.text = str(line.get("text", ""))

	# Auswahl aufbauen, falls vorhanden.
	for c in _choice_box.get_children():
		c.queue_free()
	if line.has("choices"):
		_choosing = true
		_choice_index = 0
		var choices: Array = line["choices"]
		for i in choices.size():
			var lbl := Label.new()
			lbl.text = str(choices[i].get("text", "..."))
			_choice_box.add_child(lbl)
		_highlight_choice()
	else:
		_choosing = false

func _highlight_choice() -> void:
	var kids := _choice_box.get_children()
	for i in kids.size():
		var lbl: Label = kids[i]
		if i == _choice_index:
			lbl.text = "> " + lbl.text.trim_prefix("> ")
			lbl.add_theme_color_override("font_color", Color("ffd35e"))
		else:
			lbl.text = lbl.text.trim_prefix("> ")
			lbl.add_theme_color_override("font_color", Color("ffffff"))

func _process(_dt: float) -> void:
	if not active:
		return
	if _choosing:
		var choices: Array = _lines[_index].get("choices", [])
		if Input.is_action_just_pressed("move_up"):
			_choice_index = (_choice_index - 1 + choices.size()) % choices.size()
			_highlight_choice()
		elif Input.is_action_just_pressed("move_down"):
			_choice_index = (_choice_index + 1) % choices.size()
			_highlight_choice()
		elif Input.is_action_just_pressed("interact"):
			var chosen: Dictionary = choices[_choice_index]
			if chosen.has("action"):
				_run_action(chosen["action"])
			if chosen.has("goto"):
				_index = int(chosen["goto"])
			else:
				_index += 1
			_show_current()
	else:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("cancel"):
			_index += 1
			_show_current()

## Führt eine eingebettete Story-Aktion aus.
func _run_action(a: Dictionary) -> void:
	match str(a.get("type", "")):
		"set_flag":
			GameState.set_flag(str(a["flag"]), bool(a.get("value", true)))
		"recruit":
			GameState.recruit(str(a["id"]))
		"give_item":
			GameState.add_item(str(a["id"]), int(a.get("count", 1)))
		"start_quest":
			QuestManager.start_quest(str(a["id"]))
		"advance_quest":
			QuestManager.advance(str(a["id"]))
		"heal_party":
			for m in GameState.party:
				m.kp = m.max_kp
				m.tp = m.max_tp
		"start_battle":
			# Verzögert: erst nach dem Schließen des Dialogs starten.
			_result["start_battle"] = a.get("group", [])
			_result["is_boss"] = bool(a.get("boss", false))
			# Optionaler Dialog, der nach einem Sieg gestartet wird.
			_result["win_dialogue"] = str(a.get("win_dialogue", ""))
		"next_arc":
			_result["next_arc"] = true
		_:
			push_warning("Unbekannte Dialog-Aktion: " + str(a))

func _finish() -> void:
	active = false
	_layer.visible = false
	emit_signal("dialogue_finished", _result)
