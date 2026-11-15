class_name Projectile
extends Area2D
## Универсальная пуля. team = "player" или "enemy": пуля игнорирует свою команду.
## Модификаторы: пробивание, рикошет от стен, самонаведение.

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

var _hit: Array[Node] = []


func setup(pos: Vector2, vel: Vector2, dmg: int, p_team: String, p_color: Color, p_lifetime: float, p_radius: float) -> void:
	position = pos
	velocity = vel
	damage = dmg
	team = p_team
	color = p_color
	lifetime = p_lifetime
	radius = p_radius


func _ready() -> void:
	var shape := CollisionShape2D.new()
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

	var from := global_position
	var to := from + velocity * delta
	var query := PhysicsRayQueryParameters2D.create(from, to, WALL_MASK)
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
	if body.is_in_group("wall") or body.is_in_group(team):
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
	draw_circle(Vector2.ZERO, radius, color)
