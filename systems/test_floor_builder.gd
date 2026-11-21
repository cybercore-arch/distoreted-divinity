class_name TestFloorBuilder
extends RefCounted
## Собирает тестовый этаж 0.0 из реестра контента (ContentRegistry). Хаб в клетке (0,0):
##   вниз   — комнаты с оружием, по ITEMS_PER_ROOM пьедесталов в каждой (в порядке номеров w.N);
##   вверх  — по комнате на каждый тип врагов (в порядке номеров e.N), ENEMY_COPIES штук за раз;
##   вправо — комнаты с артефактами, по ITEMS_PER_ROOM в каждой (по качеству q1–q4, потом по номеру a.N).
## Добавил новый .tres оружия, врага или артефакта — он появится в комнатах без правок кода.

const ITEMS_PER_ROOM: int = 5
const ENEMY_COPIES: int = 2


static func build() -> FloorData:
	var result := FloorData.new()
	result.title = "0.0"
	result.start = Vector2i.ZERO

	var hub := RoomData.new()
	hub.kind = RoomData.Kind.HUB
	hub.title = "Хаб"
	result.set_room(Vector2i.ZERO, hub)

	# Вниз: оружие.
	var weapons := ContentRegistry.weapons()
	for r in ceili(float(weapons.size()) / float(ITEMS_PER_ROOM)):
		var room := RoomData.new()
		room.kind = RoomData.Kind.WEAPONS
		room.title = "Оружие %d" % (r + 1)
		for i in range(r * ITEMS_PER_ROOM, mini(weapons.size(), (r + 1) * ITEMS_PER_ROOM)):
			room.weapons.append(weapons[i])
		result.set_room(Vector2i(0, r + 1), room)

	# Вверх: враги.
	var up := 0
	for enemy in ContentRegistry.enemies():
		if not enemy.in_test_rooms:
			continue
		up += 1
		var room := RoomData.new()
		room.kind = RoomData.Kind.ENEMIES
		room.title = "Враги: %s" % enemy.display_name
		for i in ENEMY_COPIES:
			room.enemies.append(enemy)
		result.set_room(Vector2i(0, -up), room)

	# Вправо: артефакты, отсортированные по качеству и номеру.
	var artifacts := ContentRegistry.artifacts()
	artifacts.sort_custom(func(a: ArtifactData, b: ArtifactData) -> bool:
		if a.quality != b.quality:
			return a.quality < b.quality
		return a.id < b.id)
	for r in ceili(float(artifacts.size()) / float(ITEMS_PER_ROOM)):
		var room := RoomData.new()
		room.kind = RoomData.Kind.ARTIFACTS
		room.title = "Артефакты %d" % (r + 1)
		for i in range(r * ITEMS_PER_ROOM, mini(artifacts.size(), (r + 1) * ITEMS_PER_ROOM)):
			room.artifacts.append(artifacts[i])
		result.set_room(Vector2i(r + 1, 0), room)
	return result
