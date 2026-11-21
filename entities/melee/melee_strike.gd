class_name MeleeStrike
extends Node2D
## Ближний удар копьём. Два стиля (FireMode.melee_style):
## THRUST — быстрый выпад: копьё вылетает вперёд и возвращается, бьёт всех на линии (пробивает).
## SWEEP  — замах: копьё описывает полный круг вокруг игрока и бьёт каждого, мимо кого проходит.
## Каждый враг получает урон за удар не более одного раза.
## reverse (артефакт Hindsight): удар рождается на максимуме дальности и идёт к игроку —
## выпад втягивается, замах закручивается спиралью внутрь.

const TIP_LENGTH: float = 9.0
const SWEEP_START_OFFSET: float = deg_to_rad(-40.0)  ## замах начинается чуть левее направления удара
const SWEEP_TRAIL: float = deg_to_rad(110.0)  ## длина светящегося следа за остриём

var damage: int = 1
var reach: float = 56.0
var width: float = 10.0
var duration: float = 0.18
var color: Color = Color.WHITE
var style: FireMode.MeleeStyle = FireMode.MeleeStyle.THRUST
var direction: Vector2 = Vector2.RIGHT
var follow: Node2D
var reverse: bool = false

var _age: float = 0.0
var _hit: Array[Node] = []
var _start_angle: float = 0.0
var _last_extent: float = -1.0  ## где было остриё в прошлом кадре (для обратного выпада); -1 = ещё не было кадра


func setup(p_follow: Node2D, dir: Vector2, mode: FireMode) -> void:
	follow = p_follow
	direction = dir.normalized()
	damage = mode.damage
	reach = mode.melee_reach
	width = mode.melee_width
	duration = maxf(mode.melee_duration, 0.01)
	color = mode.color
	style = mode.melee_style
	_start_angle = direction.angle() + SWEEP_START_OFFSET
	position = p_follow.global_position


func _ready() -> void:
	add_to_group("transient")  # исчезает при смене комнаты


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= duration:
		queue_free()
		return
	if follow != null and is_instance_valid(follow):
		global_position = follow.global_position

	var progress := _age / duration
	if style == FireMode.MeleeStyle.THRUST:
		_hit_thrust(progress)
	else:
		_hit_sweep(progress)
	queue_redraw()


## Копьё вытягивается по sin: быстро вперёд, затем обратно. В обратном режиме остриё идёт от максимума к игроку.
func _thrust_extent(progress: float) -> float:
	if reverse:
		return reach * pow(1.0 - progress, 0.7)
	return reach * pow(sin(progress * PI), 0.6)


## Радиус замаха: обычный — постоянный, обратный — сужающаяся спираль.
func _sweep_radius(progress: float) -> float:
	return reach * (1.0 - 0.85 * progress) if reverse else reach


func _hit_thrust(progress: float) -> void:
	var extent := _thrust_extent(progress)
	var tip := direction * extent
	# Обычный выпад бьёт по всей длине копья; обратный — только там, где остриё прошло с прошлого кадра.
	var seg_from := Vector2.ZERO
	if reverse:
		seg_from = direction * (extent if _last_extent < 0.0 else _last_extent)
	_last_extent = extent
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy == null or _hit.has(enemy):
			continue
		var local := enemy.global_position - global_position
		var closest := Geometry2D.get_closest_point_to_segment(local, seg_from, tip)
		if local.distance_to(closest) <= enemy.data.radius + width * 0.5:
			_hit.append(enemy)
			enemy.take_damage(damage)


func _hit_sweep(progress: float) -> void:
	var swept := TAU * progress
	var radius := _sweep_radius(progress)
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy == null or _hit.has(enemy):
			continue
		var local := enemy.global_position - global_position
		if local.length() > radius + enemy.data.radius:
			continue
		var relative := fposmod(local.angle() - _start_angle, TAU)
		if relative <= swept:
			_hit.append(enemy)
			enemy.take_damage(damage)


func _draw() -> void:
	var progress := _age / duration
	if style == FireMode.MeleeStyle.THRUST:
		_draw_spear(direction * _thrust_extent(progress))
	else:
		var swept := TAU * progress
		var head_angle := _start_angle + swept
		var trail := minf(swept, SWEEP_TRAIL)
		var steps := 10
		for i in steps:
			var a_new := head_angle - trail * float(i) / float(steps)
			var a_old := head_angle - trail * float(i + 1) / float(steps)
			var alpha := (1.0 - float(i) / float(steps)) * 0.55
			draw_arc(Vector2.ZERO, _sweep_radius(progress) - 2.0, a_old, a_new, 4, Color(color.r, color.g, color.b, alpha), 3.0)
		_draw_spear(Vector2.from_angle(head_angle) * _sweep_radius(progress))


## Рисует копьё от игрока до остриья: древко и наконечник-треугольник.
func _draw_spear(tip: Vector2) -> void:
	var length := tip.length()
	if length < 2.0:
		return
	var axis := tip / length
	var side := axis.orthogonal()
	var shaft_end := tip - axis * minf(TIP_LENGTH, length)
	if length > 10.0:
		draw_line(axis * 6.0, shaft_end, color.darkened(0.45), 2.0)
	draw_colored_polygon(PackedVector2Array([tip, shaft_end + side * 3.5, shaft_end - side * 3.5]), color)
