class_name DebugCommands
extends RefCounted
## debug — дебаг-флаги (DebugState): бессмертие, бесконечный альт и т.д.


func register() -> void:
	Console.register(ConsoleCommand.create("debug", PackedStringArray(["d"]), "debug [флаг] [on|off]", "дебаг-флаги: без аргументов — список, с флагом — переключить", _debug))


func _debug(args: PackedStringArray) -> void:
	if args.is_empty():
		Console.say("Дебаг-флаги:", "88ccff")
		for flag in DebugState.FLAGS:
			var state := "ВКЛ" if DebugState.get_flag(flag) else "выкл"
			Console.say("  %s [%s] — %s" % [flag, state, DebugState.FLAGS[flag]])
		return
	var flag := args[0].to_lower()
	if not DebugState.is_flag(flag):
		Console.error("нет флага «%s» (debug — список)" % args[0])
		return
	var value := not DebugState.get_flag(flag)
	if args.size() > 1:
		match args[1].to_lower():
			"on", "1", "true":
				value = true
			"off", "0", "false":
				value = false
			_:
				Console.error("второй аргумент: on или off")
				return
	DebugState.set_flag(flag, value)
	Console.ok("%s: %s" % [flag, "ВКЛ" if value else "выкл"])
