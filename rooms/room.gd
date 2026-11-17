class_name Room
extends Node2D
## Одна комната 480x270: стены, двери и содержимое по RoomData.
## Комната ничего не знает про этаж: этаж создаёт её, слушает door_used и решает, куда идти дальше.
## Комната врагов сама возрождает врагов после зачистки (для тестов).

signal door_used(direction: Door.Direction)

const SIZE := Vector2(480, 270)
const WALL: float = 16.0
const SPAWN_MARGIN: float = 34.0  ## на сколько игрок отступает от двери при входе
const PEDESTAL_SPACING: float = 70.0
const ENEMY_MIN_DISTANCE: float = 120.0  ## враги не появляются ближе к игроку
const RESPAWN_DELAY: float = 1.5

var data: RoomData
var up_title: String = ""  ## "" — двери вверх нет
var down_title: String = ""

var _player: Player
var _wave_pending: bool = false


func setup(p_data: RoomData, p_up_title: String, p_down_title: String, p_player: Player) -> void:
	data = p_data
	up_title = p_up_title
	down_title = p_down_title
	_player = p_player


func _ready() -> void:
	add_to_group("room")  # консоль и другие системы находят текущую комнату по группе
	_build_walls()
	_build_doors()
	match data.kind:
		RoomData.Kind.WEAPONS:
			_build_pedestals()
		RoomData.Kind.ENEMIES:
			EventBus.enemy_killed.connect(_on_enemy_killed)


## Вызывается после того, как игрок поставлен на место входа.
func begin() -> void:
	if data.kind == RoomData.Kind.ENEMIES:
		_spawn_enemies()


## Где появится игрок. moved — в какую сторону он шёл: вошёл вверх — оказывается внизу, и наоборот.
## Любое другое значение (старт этажа) — центр комнаты.
func spawn_position(moved: int) -> Vector2:
	if moved == Door.Direction.UP:
		return Vector2(SIZE.x * 0.5, SIZE.y - WALL - Door.SIZE.y - SPAWN_MARGIN)
	if moved == Door.Direction.DOWN:
		return Vector2(SIZE.x * 0.5, WALL + Door.SIZE.y + SPAWN_MARGIN)
	return SIZE * 0.5


## Дебаг: убрать всех врагов, следом придёт новая волна.
func clear_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.queue_free()
	_schedule_check()


# --- Сборка -----------------------------------------------------------------

func _build_walls() -> void:
	_add_wall(Vector2(SIZE.x * 0.5, WALL * 0.5), Vector2(SIZE.x, WALL))
	_add_wall(Vector2(SIZE.x * 0.5, SIZE.y - WALL * 0.5), Vector2(SIZE.x, WALL))
	_add_wall(Vector2(WALL * 0.5, SIZE.y * 0.5), Vector2(WALL, SIZE.y))
	_add_wall(Vector2(SIZE.x - WALL * 0.5, SIZE.y * 0.5), Vector2(WALL, SIZE.y))


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


func _build_doors() -> void:
	if up_title != "":
		_add_door(Door.Direction.UP, Vector2(SIZE.x * 0.5, WALL + Door.SIZE.y * 0.5), up_title)
	if down_title != "":
		_add_door(Door.Direction.DOWN, Vector2(SIZE.x * 0.5, SIZE.y - WALL - Door.SIZE.y * 0.5), down_title)


func _add_door(direction: Door.Direction, pos: Vector2, title: String) -> void:
	var door := Door.new()
	door.direction = direction
	door.title = title
	door.position = pos
	door.used.connect(func(d: Door.Direction) -> void: door_used.emit(d))
	add_child(door)


func _build_pedestals() -> void:
	var count := data.weapons.size()
	for i in count:
		var pedestal := WeaponPedestal.new()
		pedestal.weapon = data.weapons[i]
		pedestal.position = Vector2(SIZE.x * 0.5 + (float(i) - float(count - 1) * 0.5) * PEDESTAL_SPACING, SIZE.y * 0.5)
		add_child(pedestal)


# --- Враги ------------------------------------------------------------------

## Создаёт врага в случайной точке комнаты (используется и консолью: spawn e.N).
func spawn_enemy(enemy_data: EnemyData) -> Enemy:
	var enemy := Enemy.new()
	enemy.data = enemy_data
	enemy.position = _random_spawn_point()
	add_child(enemy)
	return enemy


func _spawn_enemies() -> void:
	for enemy_data in data.enemies:
		spawn_enemy(enemy_data)


func _random_spawn_point() -> Vector2:
	var pos := Vector2.ZERO
	for attempt in 12:
		pos = Vector2(
			randf_range(WALL + 24.0, SIZE.x - WALL - 24.0),
			randf_range(WALL + 24.0, SIZE.y - WALL - 24.0)
		)
		if pos.distance_to(_player.global_position) > ENEMY_MIN_DISTANCE:
			break
	return pos


func _on_enemy_killed(_enemy: Node) -> void:
	_schedule_check()


## Проверка через паузу: к этому моменту убитый уже удалён, а распавшиеся враги появились.
func _schedule_check() -> void:
	get_tree().create_timer(0.6).timeout.connect(_check_clear)


func _check_clear() -> void:
	if _wave_pending or not get_tree().get_nodes_in_group("enemy").is_empty():
		return
	_wave_pending = true
	get_tree().create_timer(RESPAWN_DELAY).timeout.connect(_respawn_wave)


func _respawn_wave() -> void:
	_wave_pending = false
	_spawn_enemies()


# --- Отрисовка --------------------------------------------------------------

func _draw() -> void:
	var wall_color := Color(0.3, 0.26, 0.4)
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.12, 0.1, 0.17))
	draw_rect(Rect2(0, 0, SIZE.x, WALL), wall_color)
	draw_rect(Rect2(0, SIZE.y - WALL, SIZE.x, WALL), wall_color)
	draw_rect(Rect2(0, 0, WALL, SIZE.y), wall_color)
	draw_rect(Rect2(SIZE.x - WALL, 0, WALL, SIZE.y), wall_color)
