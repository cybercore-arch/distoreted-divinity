class_name Projectile
extends Area2D
## Универсальная пуля. team = "player" или "enemy": пуля игнорирует свою команду.
## Модификаторы: пробивание, рикошет от стен, самонаведение.
## Внешний вид: круглая пуля (ORB) или стрела (ARROW), которая поворачивается по полёту.

const WALL_MASK: int = 2  ## стены лежат на слое 2 (и на слое 1 для столкновений тел)
const HOMING_RANGE: float = 220.0

var velocity: Vector2 = Vector2.ZERO
var damage: int = 1
var team: String = "player"
var color: Color = Color.WHITE
var radius: float = 3.0
var lifetime: float = 1.0
var pierce: int = 0  ## -1 = бесконечно
var bounces_left: int = 0
var homing: float = 0.0  ## градусов в секунду
var accel: float = 0.0  ## изменение скорости в секунду
var turn: float = 0.0  ## изгиб траектории, градусов в секунду
var visual: FireMode.ProjectileShape = FireMode.ProjectileShape.ORB
var length: float = 24.0  ## длина стрелы

var _hit: Array[Node] = []


func setup(pos: Vector2, vel: Vector2, dmg: int, p_team: String, p_color: Color, p_lifetime: float, p_radius: float) -> void:
	position = pos
	velocity = vel
	damage = dmg
	team = p_team
	color = p_color
	lifetime = p_lifetime
	radius = p_radius


func _is_arrow() -> bool:
	return visual == FireMode.ProjectileShape.ARROW


func _ready() -> void:
	add_to_group("transient")  # исчезает при смене комнаты
	var shape := CollisionShape2D.new()
	if _is_arrow():
		var rect := RectangleShape2D.new()
		rect.size = Vector2(length, radius * 2.0)
		shape.shape = rect
		rotation = velocity.angle()
	else:
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	if homing > 0.0:
		_steer(delta)
	if accel != 0.0 and velocity != Vector2.ZERO:
		velocity = velocity.normalized() * maxf(0.0, velocity.length() + accel * delta)
	if turn != 0.0:
		velocity = velocity.rotated(deg_to_rad(turn) * delta)

	var from := global_position
	var to := from + velocity * delta
	# Луч на стены смотрит на половину длины стрелы вперёд: остриё упирается в стену, а не уходит в неё.
	var ahead := velocity.normalized() * (length * 0.5 if _is_arrow() else 0.0)
	var query := PhysicsRayQueryParameters2D.create(from, to + ahead, WALL_MASK)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = to
	elif bounces_left > 0:
		bounces_left -= 1
		var normal: Vector2 = hit["normal"]
		velocity = velocity.bounce(normal)
		global_position = (hit["position"] as Vector2) + normal * 0.5
	else:
		queue_free()
		return

	if _is_arrow() and velocity != Vector2.ZERO:
		rotation = velocity.angle()


func _steer(delta: float) -> void:
	var target := _nearest_enemy()
	if target == null:
		return
	var desired := (target.global_position - global_position).normalized()
	var angle := velocity.normalized().angle_to(desired)
	var max_step := deg_to_rad(homing) * delta
	velocity = velocity.rotated(clampf(angle, -max_step, max_step))


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_dist := HOMING_RANGE
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Node2D
		if enemy == null or _hit.has(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < best_dist:
			best_dist = dist
			best = enemy
	return best


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("wall") or body.is_in_group("low_obstacle") or body.is_in_group(team):
		return
	if _hit.has(body):
		return
	_hit.append(body)
	if body.has_method("take_damage"):
		body.take_damage(damage)
	if pierce == 0:
		queue_free()
	elif pierce > 0:
		pierce -= 1


func _draw() -> void:
	if not _is_arrow():
		draw_circle(Vector2.ZERO, radius, color)
		return
	# Стрела нарисована вдоль оси X: остриё справа, оперение слева.
	var h := length * 0.5
	draw_line(Vector2(-h, 0.0), Vector2(h - 7.0, 0.0), color.darkened(0.35), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(h, 0.0), Vector2(h - 9.0, -3.5), Vector2(h - 9.0, 3.5)]), color)
	for offset in [0.0, 4.0]:
		draw_line(Vector2(-h + offset + 1.0, 0.0), Vector2(-h + offset - 2.0, -3.0), color, 1.0)
		draw_line(Vector2(-h + offset + 1.0, 0.0), Vector2(-h + offset - 2.0, 3.0), color, 1.0)
