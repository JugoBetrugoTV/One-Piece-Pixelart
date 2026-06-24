extends CharacterBody2D
class_name PlayerController
## ============================================================================
## player_controller.gd – Steuerung der Spielfigur im Top-Down-Overworld.
##
## Bewegung ist frei (pixelweise) mit move_and_slide; Kollision liefert die
## TileMapLayer (solide Tiles) und StaticBody2D-NPCs.
## Das Sprite (prozedural erzeugt) wird aus den Farben des Kapitäns gebaut.
## ============================================================================

const TILE := 16
@export var speed: float = 78.0

## Wird vom GameManager gesteuert: bei Dialog/Kampf/Menü auf false.
var controllable: bool = true
var facing: Vector2i = Vector2i.DOWN
var _last_tile: Vector2i = Vector2i(-9999, -9999)

signal tile_changed(tile: Vector2i)

@onready var _sprite: Sprite2D = $Sprite

func _ready() -> void:
	# Top-Down: kein "Boden"/keine Schwerkraft – frei in alle Richtungen.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_apply_appearance()

## Sprite aus den Farben des ersten Party-Mitglieds (Kapitän) erzeugen.
func _apply_appearance() -> void:
	if GameState.party.size() > 0:
		_sprite.texture = PlaceholderArt.make_actor(GameState.party[0].colors)

func _physics_process(_dt: float) -> void:
	var dir := Vector2.ZERO
	var blocked := DialogueManager.active or BattleManager.active or not controllable
	if not blocked:
		dir.x = Input.get_axis("move_left", "move_right")
		dir.y = Input.get_axis("move_up", "move_down")

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		_update_facing(dir)
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	var t := current_tile()
	if t != _last_tile:
		_last_tile = t
		emit_signal("tile_changed", t)

func _update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing = Vector2i.RIGHT if dir.x > 0 else Vector2i.LEFT
		_sprite.flip_h = dir.x < 0
	else:
		facing = Vector2i.DOWN if dir.y > 0 else Vector2i.UP
		_sprite.flip_h = false

func current_tile() -> Vector2i:
	return Vector2i((global_position / TILE).floor())

## Das Tile direkt vor dem Spieler – für Interaktionen mit NPCs.
func front_tile() -> Vector2i:
	return current_tile() + facing

func place_on_tile(t: Vector2i) -> void:
	global_position = Vector2(t.x * TILE + TILE / 2.0, t.y * TILE + TILE / 2.0)
	_last_tile = t
