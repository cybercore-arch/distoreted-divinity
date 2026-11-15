class_name Enemy
extends CharacterBody2D
## Враг, целиком описанный EnemyData. Держит дистанцию и стреляет кольцом пуль.

@export var data: EnemyData

var health: Health

var _fire_left: float = 1.0
var _flash: float = 0.0
var _ring_offset: float = 0.0


func _ready() -> void:
	add_to_group("enemy")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = data.radius
	shape.shape = circle
	add_child(shape)

	health = Health.new()
	add_child(health)
	health.setup(data.max_health)
	health.died.connect(_on_died)


func take_damage(amount: int) -> void:
	health.damage(amount)
	_flash = 0.08


func _physics_process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var to_player := player.global_position - global_position
	if to_player.length() > data.keep_distance:
		velocity = to_player.normalized() * data.move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	_fire_left -= delta
	if _fire_left <= 0.0:
		_fire_left = data.fire_interval
		_fire_ring()
	queue_redraw()


func _fire_ring() -> void:
	_ring_offset += 0.3
	for i in data.bullet_count:
		var angle := _ring_offset + TAU * float(i) / float(data.bullet_count)
		var bullet := Projectile.new()
		bullet.setup(global_position, Vector2.from_angle(angle) * data.bullet_speed, data.bullet_damage, "enemy", data.bullet_color, 4.0, 3.0)
		get_tree().current_scene.add_child(bullet)


func _on_died() -> void:
	EventBus.enemy_killed.emit(self)
	queue_free()


func _draw() -> void:
	var tint := Color(2, 2, 2) if _flash > 0.0 else Color.WHITE
	if data.sprite != null:
		draw_texture(data.sprite, -data.sprite.get_size() / 2.0, tint)
	else:
		draw_circle(Vector2.ZERO, data.radius, data.color * tint)
