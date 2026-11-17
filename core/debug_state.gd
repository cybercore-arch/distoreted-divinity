extends Node
## Дебаг-флаги (автозагрузка DebugState). Включаются консолью: debug <флаг> [on|off].
## Игровой код читает флаги прямо из полей (DebugState.infhp), а новые флаги
## добавляются здесь: поле + строка в FLAGS.

signal flag_changed(flag: String, on: bool)

const FLAGS := {
	"infhp": "бессмертие: игрок не получает урон",
	"infalt": "альт всегда готов и не тратит заряд",
	"infdash": "рывок без перезарядки",
	"onehit": "враги умирают с одного попадания",
}

var infhp: bool = false
var infalt: bool = false
var infdash: bool = false
var onehit: bool = false


func is_flag(flag: String) -> bool:
	return FLAGS.has(flag)


func get_flag(flag: String) -> bool:
	return bool(get(flag)) if is_flag(flag) else false


func set_flag(flag: String, on: bool) -> void:
	if not is_flag(flag):
		return
	set(flag, on)
	flag_changed.emit(flag, on)
