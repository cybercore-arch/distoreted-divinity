class_name MeleeStrike
extends Area2D
## Короткоживущий ближний удар: сектор (или круг) вокруг игрока.
## Бьёт каждого врага один раз и пробивает всех в зоне.

var damage: int = 1
var reach: float = 40.0
var arc_degrees: float = 60.0
var duration: float = 0.12
var color: Color = Color.WHITE
var direction: Vector2 = Vector2.RIGHT
var follow: Node2D

var _age: float = 0.0
var _hit: Array[Node] = []
var _points: PackedVector2Array = PackedVector2Array()


func setup(p_follow: Node2D, dir: Vector2, mode: FireMode) -> void:
	follow = p_follow
	direction = dir
	damage = mode.damage
	reach = mode.melee_reach
	arc_degrees = mode.melee_arc_degrees
	duration = mode.melee_duration
	color = mode.color
	position = p_follow.global_position


func _ready() -> void:
	rotation = direction.angle()
	var shape := CollisionShape2D.new()
	if arc_degrees >= 350.0:
		var circle := CircleShape2D.new()
		circle.radius = reach
		shape.shape = circle
	else:
		_points = _build_sector()
		var poly := ConvexPolygonShape2D.new()
		poly.set_point_cloud(_points)
		shape.shape = poly
	add_child(shape)


func _build_sector() -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	var steps := 8
	for k in range(steps + 1):
		var angle := deg_to_rad(lerpf(-arc_degrees * 0.5, arc_degrees * 0.5, float(k) / float(steps)))
		pts.append(Vector2.from_angle(angle) * reach)
	return pts


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= duration:
		queue_free()
		return
	if follow != null and is_instance_valid(follow):
		position = follow.global_position
	for body in get_overlapping_bodies():
		if body is Enemy and not _hit.has(body):
			_hit.append(body)
			(body as Enemy).take_damage(damage)
	queue_redraw()


func _draw() -> void:
	var fade := Color(color.r, color.g, color.b, 0.65 * (1.0 - _age / maxf(duration, 0.001)))
	if arc_degrees >= 350.0:
		draw_circle(Vector2.ZERO, reach, fade)
	elif _points.size() >= 3:
		draw_colored_polygon(_points, fade)
