class_name FloorData
extends Resource
## Этаж как сетка комнат: клетка (Vector2i) -> RoomData. Дверь ведёт в соседнюю клетку,
## если там есть комната; вверх это y − 1. Тестовый этаж: хаб в (0,0), оружие вниз, враги вверх, артефакты вправо.
## Позже здесь же будет генерируемая сетка в стиле Isaac.

@export var title: String = "0.0"
@export var start: Vector2i = Vector2i.ZERO  ## клетка, в которой начинается этаж

var cells: Dictionary = {}  ## Vector2i -> RoomData


func set_room(cell: Vector2i, room: RoomData) -> void:
	cells[cell] = room


func has_room(cell: Vector2i) -> bool:
	return cells.has(cell)


func room_at(cell: Vector2i) -> RoomData:
	return cells.get(cell)


## Названия комнат за дверями: {Door.Direction: название}. Направления без комнаты в словарь не попадают.
func neighbor_titles(cell: Vector2i) -> Dictionary:
	var result := {}
	for direction in [Door.Direction.UP, Door.Direction.DOWN, Door.Direction.LEFT, Door.Direction.RIGHT]:
		var neighbor: RoomData = cells.get(cell + Door.offset(direction))
		if neighbor != null:
			result[direction] = neighbor.title
	return result
