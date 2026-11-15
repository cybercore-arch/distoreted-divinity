extends Node2D
## Тестовая комната 480x270: стены, игрок, один враг, HUD.
## Позже заменится сгенерированными комнатами (systems/floor_generator).

const ROOM_SIZE := Vector2(480, 270)
const WALL := 16.0


func _ready() -> void:
	_build_walls()
	add_child(Hud.new())  # HUD раньше игрока, чтобы поймать его первые сигналы

	var player := Player.new()
	player.position = ROOM_SIZE / 2.0
	player.weapons.append(load("res://data/weapons/holy_spear.tres") as WeaponData)
	player.weapons.append(load("res://data/weapons/gold_plasma_crossbow.tres") as WeaponData)
	add_child(player)

	_spawn_enemy()
	EventBus.enemy_killed.connect(_on_enemy_killed)


func _build_walls() -> void:
	_add_wall(Vector2(ROOM_SIZE.x / 2.0, WALL / 2.0), Vector2(ROOM_SIZE.x, WALL))
	_add_wall(Vector2(ROOM_SIZE.x / 2.0, ROOM_SIZE.y - WALL / 2.0), Vector2(ROOM_SIZE.x, WALL))
	_add_wall(Vector2(WALL / 2.0, ROOM_SIZE.y / 2.0), Vector2(WALL, ROOM_SIZE.y))
	_add_wall(Vector2(ROOM_SIZE.x - WALL / 2.0, ROOM_SIZE.y / 2.0), Vector2(WALL, ROOM_SIZE.y))


func _add_wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.add_to_group("wall")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _spawn_enemy() -> void:
	var enemy := Enemy.new()
	enemy.data = load("res://data/enemies/test_dummy.tres") as EnemyData
	enemy.position = Vector2(ROOM_SIZE.x / 2.0, 70)
	add_child(enemy)


func _on_enemy_killed(_enemy: Node) -> void:
	get_tree().create_timer(1.5).timeout.connect(_spawn_enemy)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, ROOM_SIZE), Color(0.12, 0.1, 0.17))
	draw_rect(Rect2(0, 0, ROOM_SIZE.x, WALL), Color(0.3, 0.26, 0.4))
	draw_rect(Rect2(0, ROOM_SIZE.y - WALL, ROOM_SIZE.x, WALL), Color(0.3, 0.26, 0.4))
	draw_rect(Rect2(0, 0, WALL, ROOM_SIZE.y), Color(0.3, 0.26, 0.4))
	draw_rect(Rect2(ROOM_SIZE.x - WALL, 0, WALL, ROOM_SIZE.y), Color(0.3, 0.26, 0.4))
