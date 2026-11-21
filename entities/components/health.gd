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


## Меняет максимум на лету. Прибавка к максимуму добавляется и к текущему здоровью (как в Isaac),
## а при уменьшении текущее просто обрезается по новому максимуму.
func set_max(maximum: int) -> void:
	if maximum == max_health:
		return
	var delta := maximum - max_health
	max_health = maximum
	if current > 0:
		current = clampi(current + maxi(delta, 0), 1, max_health)
	changed.emit(current, max_health)


func damage(amount: int) -> void:
	if current <= 0:
		return
	current = maxi(0, current - amount)
	changed.emit(current, max_health)
	if current == 0:
		died.emit()
