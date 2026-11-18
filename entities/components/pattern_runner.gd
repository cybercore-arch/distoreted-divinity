class_name PatternRunner
extends Node2D
## Компонент: исполняет BulletPattern. Пули вылетают из позиции самого узла, поэтому
## достаточно сделать его ребёнком врага, босса или любой точки. Первый выстрел — сразу
## при start(), остальные по shot_interval; после последнего приходит finished.

signal finished

var team: String = "enemy"  ## чьи пули: враги не задевают своих
var running: bool = false

var _pattern: BulletPattern
var _aim_angle: float = 0.0
var _shot_index: int = 0
var _shots_left: int = 0
var _timer: float = 0.0
var _uses: int = 0


## aim_dir — направление на цель в момент начала атаки (для Aim.AT_PLAYER).
func start(pattern: BulletPattern, aim_dir: Vector2) -> void:
	_pattern = pattern
	_aim_angle = aim_dir.angle()
	_shot_index = 0
	_shots_left = maxi(1, pattern.shots)
	_timer = 0.0
	_uses += 1
	running = true
	_fire_next()


func stop() -> void:
	running = false


func _physics_process(delta: float) -> void:
	if not running:
		return
	_timer -= delta
	if _timer <= 0.0:
		_fire_next()


func _fire_next() -> void:
	_fire_shot(_shot_index)
	_shot_index += 1
	_shots_left -= 1
	if _shots_left <= 0:
		running = false
		finished.emit()
	else:
		_timer = _pattern.shot_interval


func _base_angle() -> float:
	match _pattern.aim:
		BulletPattern.Aim.TRACK_PLAYER:
			var player := get_tree().get_first_node_in_group("player") as Node2D
			if player != null:
				return (player.global_position - global_position).angle()
			return _aim_angle
		BulletPattern.Aim.FIXED:
			return 0.0
	return _aim_angle


func _fire_shot(index: int) -> void:
	var p := _pattern
	var rotation_deg := p.angle_offset_degrees + p.rotate_per_shot_degrees * float(index) + p.rotate_per_use_degrees * float(_uses - 1)
	var base := _base_angle() + deg_to_rad(rotation_deg)
	var count := maxi(1, p.bullets)
	for i in count:
		var offset := 0.0
		if count > 1:
			if p.arc_degrees >= 360.0:
				offset = TAU * float(i) / float(count)
			else:
				var half := deg_to_rad(p.arc_degrees) * 0.5
				offset = lerpf(-half, half, float(i) / float(count - 1))
		if p.jitter_degrees > 0.0:
			offset += deg_to_rad(randf_range(-p.jitter_degrees, p.jitter_degrees))
		_spawn_bullet(base + offset)


func _spawn_bullet(angle: float) -> void:
	var p := _pattern
	var bullet := Projectile.new()
	bullet.setup(global_position, Vector2.from_angle(angle) * p.speed, p.damage, team, p.color, p.lifetime, p.radius)
	bullet.accel = p.acceleration
	bullet.turn = p.turn_degrees_per_second
	get_tree().current_scene.add_child(bullet)
