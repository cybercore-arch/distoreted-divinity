class_name Health
extends Node
## Компонент здоровья: подключается к любой сущности.

signal changed(current: int, maximum: int)
signal died

var max_health: int = 10
var current: int = 10


func setup(maximum: int) -> void:
	max_health = maximum
	current = maximum
	changed.emit(current, max_health)


func damage(amount: int) -> void:
	if current <= 0:
		return
	current = maxi(0, current - amount)
	changed.emit(current, max_health)
	if current == 0:
		died.emit()
