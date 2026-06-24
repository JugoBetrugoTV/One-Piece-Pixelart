extends Node
## ============================================================================
## QuestManager (Autoload)
## ----------------------------------------------------------------------------
## Verwaltet den Questfortschritt. Die Quest-DEFINITIONEN stehen in der
## Arc-JSON (Feld "quests"); der FORTSCHRITT lebt in GameState.quests und wird
## mitgespeichert.
##
## Quest-Schema (in der Arc-JSON):
##   { "id":"...", "name":"...", "desc":"...",
##     "steps": [ {"id":"...", "text":"Sprich mit ..."} , ... ],
##     "reward": {"gold": 0, "items": {"id": n}, "exp": 0} }
##
## Fortschritt in GameState.quests:
##   { "<quest_id>": {"state":"aktiv"/"erledigt", "step": <index>} }
## ============================================================================

signal quest_updated(quest_id: String)

## Liefert die Definition einer Quest aus dem aktuellen Arc.
func get_def(quest_id: String) -> Dictionary:
	for q in ArcManager.current.get("quests", []):
		if q.get("id", "") == quest_id:
			return q
	return {}

## Startet eine Quest (falls noch nicht vorhanden).
func start_quest(quest_id: String) -> void:
	if GameState.quests.has(quest_id):
		return
	GameState.quests[quest_id] = {"state": "aktiv", "step": 0}
	emit_signal("quest_updated", quest_id)
	GameState.emit_signal("state_changed")

func is_active(quest_id: String) -> bool:
	return GameState.quests.get(quest_id, {}).get("state", "") == "aktiv"

func is_done(quest_id: String) -> bool:
	return GameState.quests.get(quest_id, {}).get("state", "") == "erledigt"

func current_step(quest_id: String) -> int:
	return int(GameState.quests.get(quest_id, {}).get("step", 0))

## Schiebt eine aktive Quest einen Schritt weiter. Ist der letzte Schritt
## erreicht, wird die Quest abgeschlossen und die Belohnung vergeben.
func advance(quest_id: String) -> void:
	if not is_active(quest_id):
		return
	var def := get_def(quest_id)
	var steps: Array = def.get("steps", [])
	var prog: Dictionary = GameState.quests[quest_id]
	prog.step = int(prog.step) + 1
	if prog.step >= steps.size():
		_complete(quest_id, def)
	emit_signal("quest_updated", quest_id)
	GameState.emit_signal("state_changed")

func _complete(quest_id: String, def: Dictionary) -> void:
	GameState.quests[quest_id].state = "erledigt"
	var reward: Dictionary = def.get("reward", {})
	if reward.has("gold"):
		GameState.gold += int(reward["gold"])
	if reward.has("items"):
		for item_id in reward["items"]:
			GameState.add_item(item_id, int(reward["items"][item_id]))
	if reward.has("exp"):
		for m in GameState.party:
			BattleManager.grant_exp(m, int(reward["exp"]))

## Aktuell sichtbarer Hinweistext einer Quest (für Questlog/NPC-Hinweise).
func step_text(quest_id: String) -> String:
	var def := get_def(quest_id)
	var steps: Array = def.get("steps", [])
	var i := current_step(quest_id)
	if is_done(quest_id):
		return "Erledigt."
	if i < steps.size():
		return str(steps[i].get("text", ""))
	return ""

## Alle Quests des aktuellen Arcs mit ihrem Status – für das Questlog.
func active_log() -> Array:
	var out: Array = []
	for q in ArcManager.current.get("quests", []):
		var qid: String = q.get("id", "")
		if GameState.quests.has(qid):
			out.append({
				"name": q.get("name", qid),
				"desc": q.get("desc", ""),
				"hint": step_text(qid),
				"done": is_done(qid)
			})
	return out
