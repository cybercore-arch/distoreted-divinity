extends Node2D
## Тестовая комната 480x270: стены, игрок, волны врагов, HUD.
## Дебаг: 1-5 — оружие в активный слот, Shift+1-6 — призвать врага,
## F — заполнить шкалу альта, C — убрать врагов (следом придёт новая волна).
## Позже заменится сгенерированными комнатами (systems/floor_generator).

const ROOM_SIZE := Vector2(480, 270)
const WALL := 16.0
const WAVE_SIZE: int = 3
const WEAPON_PATHS: Array[String] = [
	"res://data/weapons/holy_spear.tres",
	"res://data/weapons/righteous_wand.tres",
	"res://data/weapons/gold_plasma_crossbow.tres",
	"res://data/weapons/gall_staff.tres",
	"res://data/weapons/mirror_shard.tres",
]
const ENEMY_PATHS: Array[String] = [
	"res://data/enemies/test_dummy.tres",  # 1: стрелок кольцами
	"res://data/enemies/rusher.tres",  # 2: бежит напролом
	"res://data/enemies/sniper.tres",  # 3: прицельный веер с предупреждением
	"res://data/enemies/spinner.tres",  # 4: спираль
	"res://data/enemies/lunger.tres",  # 5: рывок
	"res://data/enemies/swarm_mother.tres",  # 6: распадается на червышей
]

var _player: Player
var _wave_pending: bool = false


func _ready() -> void:
	_build_walls()
	add_child(Hud.new())  # HUD раньше игрока, чтобы поймать его первые сигналы

	_player = Player.new()
	_player.position = ROOM_SIZE / 2.0
	_player.weapons.append(load(WEAPON_PATHS[0]) as WeaponData)
	_player.weapons.append(load(WEAPON_PATHS[1]) as WeaponData)
	add_child(_player)

	_spawn_wave()
	EventBus.enemy_killed.connect(_on_enemy_killed)


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var index: int = key_event.physical_keycode - KEY_1
	if key_event.physical_keycode == KEY_F:
		_player.add_alt_charge(Player.ALT_MAX)
	elif key_event.physical_keycode == KEY_C:
		for enemy in get_tree().get_nodes_in_group("enemy"):
			enemy.queue_free()
		_schedule_check()
	elif key_event.shift_pressed and index >= 0 and index < ENEMY_PATHS.size():
		_spawn_enemy(index)
	elif not key_event.shift_pressed and index >= 0 and index < WEAPON_PATHS.size():
		_player.equip(load(WEAPON_PATHS[index]) as WeaponData)


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


func _spawn_wave() -> void:
	for i in WAVE_SIZE:
		_spawn_enemy(randi() % ENEMY_PATHS.size())


## Враг появляется в случайной точке не ближе 120 px от игрока.
func _spawn_enemy(index: int) -> void:
	var enemy := Enemy.new()
	enemy.data = load(ENEMY_PATHS[index]) as EnemyData
	var pos := Vector2.ZERO
	for attempt in 12:
		pos = Vector2(
			randf_range(WALL + 24.0, ROOM_SIZE.x - WALL - 24.0),
			randf_range(WALL + 24.0, ROOM_SIZE.y - WALL - 24.0)
		)
		if pos.distance_to(_player.global_position) > 120.0:
			break
	enemy.position = pos
	add_child(enemy)


func _on_enemy_killed(_enemy: Node) -> void:
	_schedule_check()


## Проверка через паузу: к этому моменту убитый уже удалён, а распавшиеся враги появились.
func _schedule_check() -> void:
	get_tree().create_timer(0.6).timeout.connect(_check_clear)


func _check_clear() -> void:
	if _wave_pending or not get_tree().get_nodes_in_group("enemy").is_empty():
		return
	_wave_pending = true
	await get_tree().create_timer(1.5).timeout
	_wave_pending = false
	_spawn_wave()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, ROOM_SIZE), Color(0.12, 0.1, 0.17))
	draw_rect(Rect2(0, 0, ROOM_SIZE.x, WALL), Color(0.3, 0.26, 0.4))
	draw_rect(Rect2(0, ROOM_SIZE.y - WALL, ROOM_SIZE.x, WALL), Color(0.3, 0.26, 0.4))
	draw_rect(Rect2(0, 0, WALL, ROOM_SIZE.y), Color(0.3, 0.26, 0.4))
	draw_rect(Rect2(ROOM_SIZE.x - WALL, 0, WALL, ROOM_SIZE.y), Color(0.3, 0.26, 0.4))
