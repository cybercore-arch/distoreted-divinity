class_name DamageZone
extends Area2D
## Лужа на земле: периодически бьёт врагов внутри и ускоряет игрока внутри.

var radius: float = 45.0
var duration: float = 4.0
var tick: float = 0.25
var tick_damage: int = 1
var damage_mult: float = 1.0  ## множитель урона игрока; дробь округляется случайно (PlayerStats.roll) на каждом тике
var speed_mult: float = 1.0
var color: Color = Color(0.55, 0.75, 0.15)

var _age: float = 0.0
var _tick_left: float = 0.0


func setup(pos: Vector2, mode: FireMode) -> void:
	position = pos
	radius = mode.zone_radius
	duration = mode.zone_duration
	tick = mode.zone_tick
	tick_damage = mode.damage
	speed_mult = mode.zone_speed_mult
	color = mode.color


func _ready() -> void:
	add_to_group("transient")  # исчезает при смене комнаты
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= duration:
		queue_free()
		return

	var bodies := get_overlapping_bodies()
	if speed_mult > 1.0:
		for body in bodies:
			if body is Player:
				(body as Player).apply_speed_boost(speed_mult, 0.2)

	_tick_left -= delta
	if _tick_left <= 0.0:
		_tick_left = tick
		for body in bodies:
			if body is Enemy:
				(body as Enemy).take_damage(maxi(1, PlayerStats.roll(float(tick_damage) * damage_mult)))
	queue_redraw()


func _draw() -> void:
	var life := 1.0 - _age / maxf(duration, 0.001)
	draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, 0.18 + 0.12 * life))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(color.r, color.g, color.b, 0.6), 1.0)
