class_name EnemyData
extends Resource
## Данные врага. Новый враг = новый .tres, а не новый код.

@export var display_name: String = "Враг"
@export var sprite: Texture2D  ## позже: 32x32
@export var color: Color = Color(0.8, 0.2, 0.25)  ## плейсхолдер, пока нет спрайта
@export var radius: float = 8.0
@export var max_health: int = 30
@export var move_speed: float = 40.0
@export var keep_distance: float = 90.0
@export var fire_interval: float = 1.6
@export var bullet_count: int = 8
@export var bullet_speed: float = 90.0
@export var bullet_damage: int = 10
@export var bullet_color: Color = Color(1.0, 0.35, 0.3)
