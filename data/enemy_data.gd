class_name EnemyData
extends Resource
## Данные врага. Новый враг = новый .tres, а не новый код.
## behavior: RANGED — держит дистанцию и атакует паттернами пуль, CHARGE — бежит напролом,
## LUNGE — подходит, замирает с предупреждением и делает рывок.

enum Behavior { RANGED, CHARGE, LUNGE }
enum AttackOrder { SEQUENCE, RANDOM }  ## по очереди или случайно

@export var id: int = 0  ## номер для консоли: spawn e.N (задаётся вручную и не меняется)
@export var display_name: String = "Враг"
@export var sprite: Texture2D  ## позже: 32x32
@export var color: Color = Color(0.8, 0.2, 0.25)  ## плейсхолдер, пока нет спрайта
@export var radius: float = 8.0
@export var max_health: int = 30
@export var move_speed: float = 40.0
@export var in_test_rooms: bool = true  ## false — не получает своей комнаты на тестовом этаже (например, порождённые враги)
@export var behavior: Behavior = Behavior.RANGED
@export var contact_damage: int = 0  ## урон при касании игрока (0 = нет)
@export var contact_interval: float = 0.7  ## пауза между касаниями
@export var fire_interval: float = 1.6  ## пауза между атаками (для LUNGE — между рывками)

@export_group("Атаки (RANGED)")
@export var attacks: Array[BulletPattern] = []  ## паттерны пуль; можно несколько
@export var attack_order: AttackOrder = AttackOrder.SEQUENCE
@export var keep_distance: float = 90.0  ## ближе 70% этого значения враг отступает

@export_group("Рывок (LUNGE)")
@export var lunge_range: float = 150.0  ## с какого расстояния начинает рывок
@export var lunge_windup: float = 0.6  ## предупреждение перед рывком
@export var lunge_speed: float = 300.0
@export var lunge_duration: float = 0.45
@export var lunge_rest: float = 0.9  ## пауза после рывка, когда враг уязвим

@export_group("Распад при смерти")
@export var split_into: EnemyData
@export var split_count: int = 0
