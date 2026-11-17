class_name SpawnCommands
extends RefCounted
## spawn — создать врагов в текущей комнате, kill — убрать всех врагов.


func register() -> void:
	Console.register(ConsoleCommand.create("spawn", PackedStringArray(["s"]), "spawn <e.N> [количество]", "создать врагов в текущей комнате (до 50)", _spawn))
	Console.register(ConsoleCommand.create("kill", PackedStringArray(["killall"]), "kill", "убрать всех врагов в комнате", _kill))


func _spawn(args: PackedStringArray) -> void:
	if args.is_empty():
		Console.error("нужна ссылка на врага, например: spawn e.1  или  spawn e.2 5")
		return
	var room := Console.room()
	if room == null:
		Console.error("комната не найдена")
		return
	var found := ContentRegistry.resolve(args[0])
	if found.has("error"):
		Console.error(found["error"])
		return
	if found["kind"] != "e":
		Console.error("spawn создаёт только врагов (e.N)")
		return
	var count := 1
	if args.size() > 1:
		if not args[1].is_valid_int():
			Console.error("количество должно быть числом, а не «%s»" % args[1])
			return
		count = clampi(int(args[1]), 1, 50)
	var enemy_data := found["resource"] as EnemyData
	for i in count:
		room.spawn_enemy(enemy_data)
	Console.ok("создано: %s ×%d" % [enemy_data.display_name, count])


func _kill(_args: PackedStringArray) -> void:
	var room := Console.room()
	if room == null:
		Console.error("комната не найдена")
		return
	room.clear_enemies()
	Console.ok("враги убраны")
