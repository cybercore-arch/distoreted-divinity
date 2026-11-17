class_name ConsoleCommand
extends RefCounted
## Описание одной команды консоли. handler получает аргументы: func(args: PackedStringArray) -> void.

var name: String = ""
var aliases: PackedStringArray = PackedStringArray()
var usage: String = ""
var help: String = ""
var handler: Callable


static func create(p_name: String, p_aliases: PackedStringArray, p_usage: String, p_help: String, p_handler: Callable) -> ConsoleCommand:
	var command := ConsoleCommand.new()
	command.name = p_name
	command.aliases = p_aliases
	command.usage = p_usage
	command.help = p_help
	command.handler = p_handler
	return command
