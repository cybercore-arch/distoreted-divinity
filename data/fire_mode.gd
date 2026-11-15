class_name FireMode
extends Resource
## Один режим стрельбы (основной или альт). Только данные, без логики.

@export var fire_rate: float = 6.0  ## выстрелов в секунду
@export var damage: int = 1
@export var projectile_speed: float = 260.0
@export var projectile_lifetime: float = 1.2
@export var projectile_radius: float = 3.0
@export var pellets: int = 1  ## снарядов за выстрел
@export var spread_degrees: float = 0.0  ## общий конус разброса
@export var color: Color = Color(1.0, 0.9, 0.4)
