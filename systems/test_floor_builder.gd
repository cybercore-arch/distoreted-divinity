class_name TestFloorBuilder
extends RefCounted
## Собирает тестовый этаж 0.0 из того, что лежит в data/ (контент подхватывается сам):
##   вниз  — комнаты с оружием, по WEAPONS_PER_ROOM пьедесталов в каждой;
##   вверх — по комнате на каждый тип врагов (ENEMY_COPIES штук за раз).
## Добавил новый .tres оружия или врага — он появится в комнатах без правок кода.

const WEAPONS_DIR := "res://data/weapons"
const ENEMIES_DIR := "res://data/enemies"
const WEAPONS_PER_ROOM: int = 5
const ENEMY_COPIES: int = 2


static func build() -> FloorData:
	var weapons := _load_weapons()
	var weapon_rooms: Array[RoomData] = []  # от ближней к хабу к самой глубокой
	var weapon_room_count := ceili(float(weapons.size()) / float(WEAPONS_PER_ROOM))
	for r in weapon_room_count:
		var weapon_room := RoomData.new()
		weapon_room.kind = RoomData.Kind.WEAPONS
		weapon_room.title = "Оружие %d" % (r + 1)
		for i in range(r * WEAPONS_PER_ROOM, mini(weapons.size(), (r + 1) * WEAPONS_PER_ROOM)):
			weapon_room.weapons.append(weapons[i])
		weapon_rooms.append(weapon_room)

	var enemy_rooms: Array[RoomData] = []
	for enemy in _load_enemies():
		var enemy_room := RoomData.new()
		enemy_room.kind = RoomData.Kind.ENEMIES
		enemy_room.title = "Враги: %s" % enemy.display_name
		for i in ENEMY_COPIES:
			enemy_room.enemies.append(enemy)
		enemy_rooms.append(enemy_room)

	var hub := RoomData.new()
	hub.kind = RoomData.Kind.HUB
	hub.title = "Хаб"

	# Порядок снизу вверх: самая глубокая комната оружия ... хаб ... самая дальняя комната врагов.
	weapon_rooms.reverse()
	var result := FloorData.new()
	result.title = "0.0"
	result.rooms.append_array(weapon_rooms)
	result.hub_index = weapon_rooms.size()
	result.rooms.append(hub)
	result.rooms.append_array(enemy_rooms)
	return result


static func _load_weapons() -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	for path in _resource_paths(WEAPONS_DIR):
		var weapon := load(path) as WeaponData
		if weapon != null:
			result.append(weapon)
	return result


static func _load_enemies() -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	for path in _resource_paths(ENEMIES_DIR):
		var enemy := load(path) as EnemyData
		if enemy != null and enemy.in_test_rooms:
			result.append(enemy)
	return result


## Пути всех .tres в папке по алфавиту (в экспортированной игре к ним добавляется .remap).
static func _resource_paths(dir: String) -> PackedStringArray:
	var paths := PackedStringArray()
	for file_name in DirAccess.get_files_at(dir):
		var clean := file_name.trim_suffix(".remap")
		if clean.ends_with(".tres"):
			paths.append(dir.path_join(clean))
	paths.sort()
	return paths
