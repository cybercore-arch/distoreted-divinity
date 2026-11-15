extends Node2D
## Тестовая комната 480x270: стены, игрок, враги, HUD.
## Дебаг: клавиши 1-5 ставят оружие в активный слот, F заполняет шкалу альта.
## Позже заменится сгенерированными комнатами (systems/floor_generator).

const ROOM_SIZE := Vector2(480, 270)
const WALL := 16.0
const WEAPON_PATHS: Array[String] = [
	"res://data/weapons/holy_spear.tres",
	"res://data/weapons/righteous_wand.tres",
	"res://data/weapons/gold_plasma_crossbow.tres",
	"res://data/weapons/gall_staff.tres",
	"res://data/weapons/mirror_shard.tres",
]

var _player: Player


func _ready() -> void:
	_build_walls()
	add_child(Hud.new())  # HUD раньше игрока, чтобы поймать его первые сигналы

	_player = Player.new()
	_player.position = ROOM_SIZE / 2.0
	_player.weapons.append(load(WEAPON_PATHS[0]) as WeaponData)
	_player.weapons.append(load(WEAPON_PATHS[1]) as WeaponData)
	add_child(_player)

	_spawn_enemy()
	_spawn_enemy()
	EventBus.enemy_killed.connect(_on_enemy_killed)


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var index: int = key_event.physical_keycode - KEY_1
	if index >= 0 and index < WEAPON_PATHS.size():
		_player.equip(load(WEAPON_PATHS[index]) as WeaponData)
	elif key_event.physical_keycode == KEY_F:
		_player.add_alt_charge(Player.ALT_MAX)


func _build_walls() -> void:
	_add_wall(Vector2(ROOM_SIZE.x / 2.0, WALL / 2.0), Vector2(ROOM_SIZE.x, WALL))
	_add_wall(Vector2(ROOM_SIZE.x / 2.0, ROOM_SIZE.y - WALL / 2.0), Vector2(ROOM_SIZE.x, WALL))
	_add_wall(Vector2(WALL / 2.0, ROOM_SIZE.y / 2.0), Vector2(WALL, ROOM_SIZE.y))
	_add_wall(Vector2(ROOM_SIZE.x - WALL / 2.0, ROOM_SIZE.y / 2.0), Vector2(WALL, ROOM_SIZE.y))


func _add_wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.add_to_group("wall")
	body.collision_layer = 3  # слой 1 (столкновения тел) + слой 2 (лучи пуль для рикошета)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _spawn_enemy() -> void:
	var enemy := Enemy.new()
	enemy.data = load("res://data/enemies/test_dummy.tres") as EnemyData
	enemy.position = Vector2(randf_range(100.0, 380.0), 70.0)
	add_child(enemy)


func _on_enemy_killed(_enemy: Node) -> void:
	get_tree().create_timer(1.5).timeout.connect(_spawn_enemy)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, ROOM_SIZE), Color(0.12, 0.1, 0.17))
	draw_rect(Rect2(0, 0, ROOM_SIZE.x, WALL), Color(0.3, 0.26, 0.4))
	draw_rect(Rect2(0, ROOM_SIZE.y - WALL, ROOM_SIZE.x, WALL), Color(0.3, 0.26, 0.4))
	draw_rect(Rect2(0, 0, WALL, ROOM_SIZE.y), Color(0.3, 0.26, 0.4))
	draw_rect(Rect2(ROOM_SIZE.x - WALL, 0, WALL, ROOM_SIZE.y), Color(0.3, 0.26, 0.4))
