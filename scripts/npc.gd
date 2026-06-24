extends StaticBody2D
class_name NpcActor
## ============================================================================
## npc.gd – Ein NPC im Overworld. Blockiert die Bewegung (StaticBody2D) und
## trägt eine Dialog-ID, die beim Ansprechen ausgelöst wird.
##
## NPC-Daten kommen aus der Arc-JSON (map.npcs):
##   { "id":"makina", "x":8, "y":6, "colors":{...},
##     "dialogue":"makina_intro",          # Dialog-ID im Arc
##     "facing_player": true }
## ============================================================================

const TILE := 16
var data: Dictionary = {}

@onready var _sprite: Sprite2D = $Sprite

func setup(d: Dictionary) -> void:
	data = d
	var colors: Dictionary = d.get("colors", {"skin": "f0c090", "hair": "503010", "shirt": "5aa0d0", "pants": "404040"})
	# texture muss evtl. vor _ready gesetzt werden -> _sprite ist dann noch null
	if _sprite == null:
		_sprite = $Sprite
	_sprite.texture = PlaceholderArt.make_actor(colors)
	place_on_tile(Vector2i(int(d.get("x", 0)), int(d.get("y", 0))))

func place_on_tile(t: Vector2i) -> void:
	position = Vector2(t.x * TILE + TILE / 2.0, t.y * TILE + TILE / 2.0)

func tile() -> Vector2i:
	return Vector2i((position / TILE).floor())

## Liefert die ID des auszulösenden Dialogs.
func dialogue_id() -> String:
	return str(data.get("dialogue", ""))
