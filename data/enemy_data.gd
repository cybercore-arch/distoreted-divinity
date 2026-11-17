class_name EnemyData
extends Resource
## Данные врага. Новый враг = новый .tres, а не новый код.
## behavior: RANGED — держит дистанцию и стреляет паттерном, CHARGE — бежит напролом,
## LUNGE — подходит, замирает с предупреждением и делает рывок.

enum Behavior { RANGED, CHARGE, LUNGE }
enum Pattern { RING, AIMED, SPIRAL }

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

@export_group("Стрельба (RANGED)")
@export var pattern: Pattern = Pattern.RING
@export var keep_distance: float = 90.0  ## ближе 70% этого значения враг отступает
@export var fire_interval: float = 1.6  ## пауза между атаками (для LUNGE — между рывками)
@export var telegraph_time: float = 0.0  ## предупреждение перед выстрелом (0 = без)
@export var burst_shots: int = 1  ## выстрелов за серию
@export var shot_interval: float = 0.1  ## пауза между выстрелами серии
@export var bullet_count: int = 8  ## пуль за выстрел (для SPIRAL — число лучей)
@export var fan_degrees: float = 0.0  ## веер для AIMED
@export var spiral_turn: float = 0.3  ## поворот спирали за выстрел, радиан
@export var bullet_speed: float = 90.0
@export var bullet_damage: int = 10
@export var bullet_color: Color = Color(1.0, 0.35, 0.3)
@export var bullet_radius: float = 3.0
@export var bullet_lifetime: float = 4.0

@export_group("Рывок (LUNGE)")
@export var lunge_range: float = 150.0  ## с какого расстояния начинает рывок
@export var lunge_windup: float = 0.6  ## предупреждение перед рывком
@export var lunge_speed: float = 300.0
@export var lunge_duration: float = 0.45
@export var lunge_rest: float = 0.9  ## пауза после рывка, когда враг уязвим

@export_group("Распад при смерти")
@export var split_into: EnemyData
@export var split_count: int = 0
