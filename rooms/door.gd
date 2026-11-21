class_name Door
extends Area2D
## Дверь между комнатами: игрок коснулся — комната сменяется. Подписана названием комнаты за ней.

enum Direction { UP, DOWN, LEFT, RIGHT }

signal used(direction: Direction)

const SIZE := Vector2(40.0, 12.0)  ## для дверей вверх и вниз; боковые двери повёрнуты (ширина и высота меняются местами)

var direction: Direction = Direction.UP
var title: String = ""


## Шаг по сетке комнат: вверх — это y − 1.
static func offset(dir: Direction) -> Vector2i:
	match dir:
		Direction.UP:
			return Vector2i(0, -1)
		Direction.DOWN:
			return Vector2i(0, 1)
		Direction.LEFT:
			return Vector2i(-1, 0)
	return Vector2i(1, 0)


func _size() -> Vector2:
	return SIZE if direction == Direction.UP or direction == Direction.DOWN else Vector2(SIZE.y, SIZE.x)


func _ready() -> void:
	collision_layer = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = _size()
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		used.emit(direction)


func _draw() -> void:
	var size := _size()
	draw_rect(Rect2(-size * 0.5, size), Color(0.9, 0.75, 0.3, 0.55))
	var font := ThemeDB.fallback_font
	var color := Color(1, 1, 1, 0.7)
	match direction:
		Direction.UP:
			draw_string(font, Vector2(-70.0, 34.0), title, HORIZONTAL_ALIGNMENT_CENTER, 140.0, 8, color)  # ниже строк HUD
		Direction.DOWN:
			draw_string(font, Vector2(-70.0, -12.0), title, HORIZONTAL_ALIGNMENT_CENTER, 140.0, 8, color)
		Direction.LEFT:
			draw_string(font, Vector2(10.0, 3.0), title, HORIZONTAL_ALIGNMENT_LEFT, 140.0, 8, color)
		Direction.RIGHT:
			draw_string(font, Vector2(-150.0, 3.0), title, HORIZONTAL_ALIGNMENT_RIGHT, 140.0, 8, color)
