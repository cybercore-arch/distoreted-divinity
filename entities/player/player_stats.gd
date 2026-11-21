class_name PlayerStats
extends RefCounted
## Характеристики игрока: база + артефакты. Единственное место, где считаются итоговые значения.
## Остальной код спрашивает final(stat, база) и has_perk(perk) и ничего не знает про конкретные артефакты.
## Условные правки (пока здоровье высокое, после убийства) читают health_fraction и recent_kill,
## которые игрок обновляет сам.

const MIN_DASH_COOLDOWN: float = 0.5
const HIGH_HEALTH: float = 0.8
const EPS: float = 0.005

var artifacts: Array[ArtifactData] = []
var health_fraction: float = 1.0
var recent_kill: bool = false


## (база + все ADD) × все MULT.
func final(stat: StatModifier.Stat, base: float) -> float:
	var add := 0.0
	var mult := 1.0
	for artifact in artifacts:
		for modifier in artifact.modifiers:
			if modifier.stat != stat or not _active(modifier.condition):
				continue
			if modifier.op == StatModifier.Op.ADD:
				add += modifier.value
			else:
				mult *= modifier.value
	return (base + add) * mult


func has_perk(perk: ArtifactData.Perk) -> bool:
	for artifact in artifacts:
		if artifact.perks.has(perk):
			return true
	return false


## Целое число из дробного: дробная часть — это шанс округлить вверх, поэтому в среднем значение точное.
## (Урон 1 с множителем 1.15 даёт 2 в 15% случаев, а не пропадает.)
static func roll(value: float) -> int:
	var whole := floori(value)
	return whole + (1 if randf() < value - float(whole) else 0)


## Целый урон/значение base, умноженное на характеристику; не меньше 1, если base > 0.
func scale_int(base: int, stat: StatModifier.Stat) -> int:
	if base <= 0:
		return base
	return maxi(1, roll(float(base) * final(stat, 1.0)))


## Подписанные строки для боковой панели: [{name, text, trend}], trend: 1 лучше базы, -1 хуже, 0 как база.
## Основные характеристики видны всегда, остальные — только когда артефакты их изменили (панель не разрастается).
func describe(base_dash_cooldown: float) -> Array:
	var lines: Array = []
	_add_line(lines, "Урон", final(StatModifier.Stat.DAMAGE, 1.0), 1.0, true, true)
	_add_line(lines, "Скорострельность", final(StatModifier.Stat.FIRE_RATE, 1.0), 1.0, true, true)
	_add_line(lines, "Скорость", final(StatModifier.Stat.MOVE_SPEED, 1.0), 1.0, true, true)
	var dash := maxf(MIN_DASH_COOLDOWN, final(StatModifier.Stat.DASH_COOLDOWN, base_dash_cooldown))
	_add_line(lines, "Рывок, с", dash, base_dash_cooldown, false, true)
	_add_line(lines, "Скорость пуль", final(StatModifier.Stat.SHOT_SPEED, 1.0), 1.0, true, false)
	_add_line(lines, "Дальность", final(StatModifier.Stat.RANGE, 1.0), 1.0, true, false)
	_add_line(lines, "Получаемый урон", final(StatModifier.Stat.DAMAGE_TAKEN, 1.0), 1.0, false, false)
	return lines


func _add_line(lines: Array, label: String, value: float, base: float, higher_is_better: bool, always: bool) -> void:
	var trend := 0
	if absf(value - base) > EPS:
		trend = 1 if (value > base) == higher_is_better else -1
	if trend == 0 and not always:
		return
	var text := "%.1f" % value if label == "Рывок, с" else "×%.2f" % value
	lines.append({"name": label, "text": text, "trend": trend})


func _active(condition: StatModifier.Condition) -> bool:
	match condition:
		StatModifier.Condition.HEALTH_HIGH:
			return health_fraction > HIGH_HEALTH
		StatModifier.Condition.RECENT_KILL:
			return recent_kill
	return true
