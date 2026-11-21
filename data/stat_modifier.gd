class_name StatModifier
extends Resource
## Одна правка характеристики игрока. Артефакт хранит список таких правок (ArtifactData.modifiers).
## Итог считает PlayerStats: (база + все ADD) × все MULT, учитываются только правки, чьё условие выполнено.

enum Stat {
	MAX_HEALTH,    ## макс. здоровье (ADD в очках)
	MOVE_SPEED,    ## скорость движения (множитель)
	DAMAGE,        ## урон игрока (множитель)
	FIRE_RATE,     ## скорострельность основного огня (множитель)
	SHOT_SPEED,    ## скорость пуль (множитель; дальность от неё не зависит)
	RANGE,         ## дальность пуль и ближнего удара (множитель)
	DASH_COOLDOWN, ## перезарядка рывка (ADD в секундах, отрицательное = быстрее)
	DAMAGE_TAKEN,  ## получаемый урон (множитель; меньше 1 = игрок крепче)
	WEAPON_SLOTS,  ## слоты оружия (ADD)
}
enum Op { ADD, MULT }
enum Condition {
	ALWAYS,       ## всегда
	HEALTH_HIGH,  ## пока здоровье выше 80%
	RECENT_KILL,  ## 2 секунды после убийства врага
}

@export var stat: Stat = Stat.DAMAGE
@export var op: Op = Op.MULT
@export var value: float = 1.0
@export var condition: Condition = Condition.ALWAYS
