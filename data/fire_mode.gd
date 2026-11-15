class_name FireMode
extends Resource
## Один режим применения оружия (основной или альт). Только данные, без логики.
## Тип (kind) решает, что делает режим: пули, ближний удар или зона вокруг игрока.

enum Kind { PROJECTILE, MELEE, ZONE }

@export var kind: Kind = Kind.PROJECTILE
@export var fire_rate: float = 6.0  ## применений в секунду (для альта не важно)
@export var damage: int = 1
@export var color: Color = Color(1.0, 0.9, 0.4)

@export_group("Снаряды")
@export var projectile_speed: float = 260.0
@export var projectile_lifetime: float = 1.2
@export var projectile_radius: float = 3.0
@export var pellets: int = 1  ## снарядов за выстрел
@export var spread_degrees: float = 0.0  ## общий конус; 360 = равномерное кольцо

@export_group("Модификаторы снарядов")
@export var pierce: int = 0  ## через скольких врагов проходит (останавливается на следующем); -1 = бесконечно
@export var bounces: int = 0  ## рикошетов от стен
@export var homing_degrees: float = 0.0  ## самонаведение, градусов в секунду

@export_group("Ближний удар")
@export var melee_reach: float = 40.0
@export var melee_arc_degrees: float = 60.0  ## 350+ = круг вокруг игрока
@export var melee_duration: float = 0.12

@export_group("Ускорение игрока после применения")
@export var speed_boost: float = 1.0  ## множитель скорости (ограничен в Player.MAX_SPEED_MULT)
@export var speed_boost_duration: float = 0.0

@export_group("Зона")
@export var zone_radius: float = 45.0
@export var zone_duration: float = 4.0
@export var zone_tick: float = 0.25  ## как часто зона бьёт врагов
@export var zone_speed_mult: float = 1.0  ## ускорение игрока внутри зоны
