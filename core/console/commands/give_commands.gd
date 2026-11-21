class_name GiveCommands
extends RefCounted
## give — выдать игроку оружие или артефакт; drop — забрать артефакты (для проверки стаков и лимитов).


func register() -> void:
	Console.register(ConsoleCommand.create("give", PackedStringArray(["g"]), "give <w.N|a.N> [ещё ссылки…]", "выдать оружие или артефакт (оружие: свободный слот или замена активного)", _give))
	Console.register(ConsoleCommand.create("drop", PackedStringArray([]), "drop <a.N|all>", "убрать у игрока артефакт (один экземпляр) или все сразу", _drop))


func _give(args: PackedStringArray) -> void:
	if args.is_empty():
		Console.error("нужна ссылка, например: give w.1  или  give a.1")
		return
	var player := Console.player()
	if player == null:
		Console.error("игрок не найден")
		return
	for ref in args:
		var found := ContentRegistry.resolve(ref)
		if found.has("error"):
			Console.error(found["error"])
			continue
		match found["kind"]:
			"w":
				var weapon := found["resource"] as WeaponData
				var replaced := player.pick_up(weapon)
				if replaced != null:
					Console.ok("оружие: %s (заменено: %s)" % [weapon.display_name, replaced.display_name])
				else:
					Console.ok("оружие: %s" % weapon.display_name)
			"a":
				var artifact := found["resource"] as ArtifactData
				player.add_artifact(artifact)
				Console.ok("артефакт: %s" % artifact.display_name)
			"e":
				Console.error("врагов не выдают, используй: spawn %s" % ref)
			"p":
				Console.error("паттерны не выдают, используй: fire %s" % ref)


func _drop(args: PackedStringArray) -> void:
	var player := Console.player()
	if player == null:
		Console.error("игрок не найден")
		return
	if args.is_empty():
		Console.error("нужна ссылка или all, например: drop a.2  или  drop all")
		return
	if args[0].to_lower() == "all":
		var count := player.artifacts.size()
		player.clear_artifacts()
		Console.ok("убрано артефактов: %d" % count)
		return
	for ref in args:
		var found := ContentRegistry.resolve(ref)
		if found.has("error"):
			Console.error(found["error"])
		elif found["kind"] != "a":
			Console.error("убирать можно только артефакты (a.N): %s" % ref)
		elif player.remove_artifact(found["resource"] as ArtifactData):
			Console.ok("убран: %s" % (found["resource"] as ArtifactData).display_name)
		else:
			Console.error("у игрока нет: %s" % ref)
