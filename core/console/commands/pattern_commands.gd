class_name PatternCommands
extends RefCounted
## fire — выпустить паттерн пуль, чтобы проверить его вживую (удобно для дизайна атак).


func register() -> void:
	Console.register(ConsoleCommand.create("fire", PackedStringArray(["f"]), "fire <p.N> [here]", "выпустить паттерн пуль сверху комнаты в игрока (here — из позиции игрока)", _fire))


func _fire(args: PackedStringArray) -> void:
	if args.is_empty():
		Console.error("нужна ссылка на паттерн, например: fire p.3  (номера: list p)")
		return
	var room := Console.room()
	var player := Console.player()
	if room == null or player == null:
		Console.error("комната или игрок не найдены")
		return
	var found := ContentRegistry.resolve(args[0])
	if found.has("error"):
		Console.error(found["error"])
		return
	if found["kind"] != "p":
		Console.error("fire выпускает только паттерны (p.N)")
		return
	var pattern := found["resource"] as BulletPattern
	var runner := PatternRunner.new()
	runner.team = "enemy"
	var from_player := args.size() > 1 and args[1].to_lower() in ["here", "тут"]
	runner.position = player.global_position if from_player else Vector2(Room.SIZE.x * 0.5, Room.WALL + 40.0)
	room.add_child(runner)
	runner.finished.connect(runner.queue_free)
	var aim := player.global_position - runner.position
	runner.start(pattern, aim.normalized() if aim != Vector2.ZERO else Vector2.DOWN)
	Console.ok("паттерн: %s" % pattern.display_name)
