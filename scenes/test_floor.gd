extends Node2D
## Тестовый этаж 0.0: хаб в центре, вниз — комнаты с оружием, вверх — комнаты с врагами.
## Этаж владеет игроком и HUD, создаёт текущую комнату и переключает комнаты по дверям.
## Дебаг: F — заполнить шкалу альта, C — убрать врагов (следом придёт новая волна).

const DEFAULT_WEAPON_PATH := "res://data/weapons/holy_spear.tres"

var _floor: FloorData
var _index: int = 0
var _room: Room
var _player: Player
var _switching: bool = false


func _ready() -> void:
	_floor = TestFloorBuilder.build()
	add_child(Hud.new())  # HUD раньше игрока, чтобы поймать его первые сигналы

	_player = Player.new()
	_player.weapons.append(load(DEFAULT_WEAPON_PATH) as WeaponData)
	add_child(_player)

	_enter_room(_floor.hub_index, -1)


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.physical_keycode == KEY_F:
		_player.add_alt_charge(Player.ALT_MAX)
	elif key_event.physical_keycode == KEY_C and _room != null:
		_room.clear_enemies()


func _on_door_used(direction: Door.Direction) -> void:
	if _switching:
		return
	_switching = true
	# Сигнал пришёл из физики: менять дерево сцены можно только отложенно.
	_switch_room.call_deferred(direction)


func _switch_room(direction: Door.Direction) -> void:
	var step := 1 if direction == Door.Direction.UP else -1
	var target := _index + step
	if target >= 0 and target < _floor.rooms.size():
		_enter_room(target, direction)
	_switching = false


## moved — в какую сторону игрок прошёл через дверь (Door.Direction) или -1 на старте.
func _enter_room(index: int, moved: int) -> void:
	_index = index
	_clear_transients()
	if _room != null:
		remove_child(_room)
		_room.queue_free()

	var data := _floor.rooms[index]
	_room = Room.new()
	_room.setup(data, _floor.title_above(index), _floor.title_below(index), _player)
	_room.door_used.connect(_on_door_used)
	add_child(_room)
	move_child(_room, 0)  # комната рисуется под игроком

	_player.teleport(_room.spawn_position(moved))
	_room.begin()
	EventBus.room_changed.emit("%s · %s" % [_floor.title, data.title])


## Пули, удары и лужи прошлой комнаты не переходят в следующую.
func _clear_transients() -> void:
	for node in get_tree().get_nodes_in_group("transient"):
		node.queue_free()
