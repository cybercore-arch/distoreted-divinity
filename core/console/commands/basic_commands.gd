class_name BasicCommands
extends RefCounted
## Служебные команды консоли: help, list, clear.


func register() -> void:
	Console.register(ConsoleCommand.create("help", PackedStringArray(["h", "?"]), "help [команда]", "список команд или справка по одной", _help))
	Console.register(ConsoleCommand.create("list", PackedStringArray(["l", "ls"]), "list [w|a|e]", "номера оружия, артефактов и врагов", _list))
	Console.register(ConsoleCommand.create("clear", PackedStringArray(["cls"]), "clear", "очистить консоль", _clear))


func _help(args: PackedStringArray) -> void:
	if args.is_empty():
		Console.say("Команды (help <команда> — подробнее):", "88ccff")
		for command in Console.commands():
			Console.say("  %s — %s" % [command.usage, command.help])
		Console.say("Ссылки: w.N оружие · a.N артефакт · e.N враг (номера: list). Также по имени файла: w.holy_spear", "aaaaaa")
		return
	var command := Console.find_command(args[0].to_lower())
	if command == null:
		Console.error("нет команды «%s»" % args[0])
		return
	Console.say(command.usage, "88ccff")
	Console.say(command.help)
	if not command.aliases.is_empty():
		Console.say("алиасы: " + ", ".join(command.aliases), "aaaaaa")


func _list(args: PackedStringArray) -> void:
	var kinds: Array = ContentRegistry.KIND_NAMES.keys()
	if not args.is_empty():
		var kind := ContentRegistry.normalize_kind(args[0])
		if kind == "":
			Console.error("неизвестный тип «%s» (w, a, e)" % args[0])
			return
		kinds = [kind]
	for kind in kinds:
		Console.say("%s:" % ContentRegistry.KIND_NAMES[kind], "88ccff")
		var entries := ContentRegistry.entries(kind)
		if entries.is_empty():
			Console.say("  (пусто)", "aaaaaa")
		for entry in entries:
			var number := "%s.%d" % [kind, entry["id"]] if entry["id"] > 0 else "%s.?" % kind
			Console.say("  %s  %s  (%s)" % [number, ContentRegistry.display_name_of(entry["resource"]), entry["stem"]])


func _clear(_args: PackedStringArray) -> void:
	Console.clear()
