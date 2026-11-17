class_name FloorData
extends Resource
## Этаж как вертикальная цепочка комнат (снизу вверх). Дверь вверх ведёт в rooms[i + 1],
## дверь вниз — в rooms[i - 1]. Позже здесь же будет сетка комнат в стиле Isaac.

@export var title: String = "0.0"
@export var rooms: Array[RoomData] = []
@export var hub_index: int = 0  ## комната, в которой начинается этаж


func has_up(index: int) -> bool:
	return index + 1 < rooms.size()


func has_down(index: int) -> bool:
	return index > 0


## Название комнаты за дверью вверх ("" — двери нет).
func title_above(index: int) -> String:
	return rooms[index + 1].title if has_up(index) else ""


## Название комнаты за дверью вниз ("" — двери нет).
func title_below(index: int) -> String:
	return rooms[index - 1].title if has_down(index) else ""
