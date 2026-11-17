class_name TestFloorBuilder
extends RefCounted
## Собирает тестовый этаж 0.0 из реестра контента (ContentRegistry):
##   вниз  — комнаты с оружием, по WEAPONS_PER_ROOM пьедесталов в каждой (в порядке номеров w.N);
##   вверх — по комнате на каждый тип врагов (в порядке номеров e.N), ENEMY_COPIES штук за раз.
## Добавил новый .tres оружия или врага — он появится в комнатах без правок кода.

const WEAPONS_PER_ROOM: int = 5
const ENEMY_COPIES: int = 2


static func build() -> FloorData:
	var weapons := ContentRegistry.weapons()
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
	for enemy in ContentRegistry.enemies():
		if not enemy.in_test_rooms:
			continue
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
