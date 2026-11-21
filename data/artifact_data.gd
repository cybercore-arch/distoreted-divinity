class_name ArtifactData
extends Resource
## Артефакт: пассивный предмет, только данные. Эффект = правки характеристик (modifiers)
## и/или особые механики (perks). Код, который их исполняет, живёт в PlayerStats, Player и ArtifactEffects.
## Качество q1–q4 как в Isaac: q1–q2 в основном числа, с q3 — механика без минусов.

## Особые механики. Новая механика = новая строка здесь + её реализация (искать по имени в коде).
enum Perk {
	HOMING,      ## все пули игрока самонаводящиеся
	RICOCHET,    ## все пули игрока рикошетят от стен
	DOUBLE_DASH, ## два рывка подряд на одну перезарядку
	SLOW_IMMUNE, ## замедления и помехи движению не действуют
	HINDSIGHT,   ## пули рождаются в конце пути и летят к игроку; ближний удар — на максимуме дальности
	SHARD_BURST, ## убитый враг разлетается кольцом осколков
	EMBER_TRAIL, ## рывок оставляет полосу урона
	LAST_STAND,  ## один раз переживает смертельный удар (1 HP, неуязвимость, взрывная волна)
}

const QUALITY_COLORS: Array[Color] = [
	Color(0.8, 0.8, 0.85),   # q1
	Color(0.5, 0.9, 0.55),   # q2
	Color(0.7, 0.55, 1.0),   # q3
	Color(1.0, 0.8, 0.3),    # q4
]

@export var id: int = 0  ## номер для консоли: give a.N (задаётся вручную и не меняется)
@export var display_name: String = "Artifact"
@export_multiline var description: String = ""
@export_range(1, 4) var quality: int = 1
@export var pool: String = "citadel"  ## из какого пула выпадает (цитадель, позже желчь, сумрак…)
@export var tags: PackedStringArray = []
@export var modifiers: Array[StatModifier] = []
@export var perks: Array[Perk] = []

@export_group("Внешний вид")
@export var icon: Texture2D  ## предмет 64x64 (пьедестал, инвентарь)
@export var body_layer: Texture2D  ## слой поверх персонажа 32x32: так артефакт меняет его внешний вид
@export var layer_order: int = 0  ## порядок слоёв: меньше — ближе к телу


func quality_color() -> Color:
	return QUALITY_COLORS[clampi(quality, 1, 4) - 1]
