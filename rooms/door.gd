class_name Door
extends Area2D
## Дверь между комнатами: игрок коснулся — комната сменяется. Подписана названием комнаты за ней.

enum Direction { UP, DOWN }

signal used(direction: Direction)

const SIZE := Vector2(40.0, 12.0)

var direction: Direction = Direction.UP
var title: String = ""


func _ready() -> void:
	collision_layer = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		used.emit(direction)


func _draw() -> void:
	draw_rect(Rect2(-SIZE * 0.5, SIZE), Color(0.9, 0.75, 0.3, 0.55))
	var label_y := 22.0 if direction == Direction.UP else -12.0
	draw_string(ThemeDB.fallback_font, Vector2(-70.0, label_y), title, HORIZONTAL_ALIGNMENT_CENTER, 140.0, 8, Color(1, 1, 1, 0.7))
