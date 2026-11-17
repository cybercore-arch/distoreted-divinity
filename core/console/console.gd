extends CanvasLayer
## Консоль разработчика (автозагрузка Console). Открывается клавишей ` (под Esc, на русской раскладке «ё»).
## Пока консоль открыта, игра на паузе. Enter — выполнить, стрелки вверх/вниз — история, Tab — дополнить имя команды.
##
## Сама консоль знает только про ввод, вывод и реестр команд. Сами команды лежат
## в core/console/commands/ и регистрируются через register(): новая группа команд —
## новый файл и одна строка в PROVIDER_PATHS.

const TOGGLE_KEY: Key = KEY_QUOTELEFT
const PANEL_HEIGHT: float = 120.0
const MAX_HISTORY: int = 50
const PROVIDER_PATHS: Array[String] = [
	"res://core/console/commands/basic_commands.gd",
	"res://core/console/commands/give_commands.gd",
	"res://core/console/commands/spawn_commands.gd",
	"res://core/console/commands/debug_commands.gd",
]

var _commands: Dictionary = {}  ## имя или алиас -> ConsoleCommand
var _ordered: Array[ConsoleCommand] = []  ## команды в порядке регистрации (для help)
var _providers: Array[RefCounted] = []
var _panel: PanelContainer
var _log: RichTextLabel
var _input: LineEdit
var _history: Array[String] = []
var _history_pos: int = 0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS  # работает и на паузе
	_build_ui()
	# Группы команд грузятся по пути, чтобы консоль не зависела от них при разборе скриптов
	# (сами команды обращаются к Console, а не наоборот).
	for path in PROVIDER_PATHS:
		var provider := (load(path) as GDScript).new() as RefCounted
		_providers.append(provider)
		provider.call("register")
	say("Консоль готова. help — список команд.", "88ccff")


# --- API для команд ---------------------------------------------------------

func register(command: ConsoleCommand) -> void:
	_ordered.append(command)
	_commands[command.name] = command
	for alias in command.aliases:
		_commands[alias] = command


func commands() -> Array[ConsoleCommand]:
	return _ordered


func find_command(command_name: String) -> ConsoleCommand:
	return _commands.get(command_name) as ConsoleCommand


func say(text: String, color: String = "dddddd") -> void:
	_log.append_text("[color=#%s]%s[/color]\n" % [color, text.replace("[", "[lb]")])


func ok(text: String) -> void:
	say(text, "88ee88")


func error(text: String) -> void:
	say("ошибка: " + text, "ff7777")


func clear() -> void:
	_log.clear()


## Текущий игрок или null.
func player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


## Текущая комната или null.
func room() -> Room:
	return get_tree().get_first_node_in_group("room") as Room


## Выполняет строку так, будто её ввели в консоли.
func run(line: String) -> void:
	say("> " + line, "888888")
	var parts := line.split(" ", false)
	if parts.is_empty():
		return
	var command := find_command(parts[0].to_lower())
	if command == null:
		error("неизвестная команда «%s», help — список" % parts[0])
		return
	command.handler.call(parts.slice(1))


# --- Интерфейс --------------------------------------------------------------

func _build_ui() -> void:
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.88)
	_panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.custom_minimum_size = Vector2(0.0, PANEL_HEIGHT - 20.0)
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 8)
	box.add_child(_log)

	_input = LineEdit.new()
	_input.placeholder_text = "команда…  (help)"
	_input.add_theme_font_size_override("font_size", 9)
	_input.text_submitted.connect(_on_submit)
	_input.gui_input.connect(_on_input_gui)
	box.add_child(_input)

	_panel.add_child(box)
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_panel.visible = false


func _set_open(open: bool) -> void:
	_panel.visible = open
	get_tree().paused = open
	if open:
		_input.clear()
		_input.grab_focus()
	else:
		_input.release_focus()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == TOGGLE_KEY:
		_set_open(not _panel.visible)
		get_viewport().set_input_as_handled()  # символ ` не попадёт в строку ввода
	elif key.physical_keycode == KEY_ESCAPE and _panel.visible:
		_set_open(false)
		get_viewport().set_input_as_handled()


func _on_submit(text: String) -> void:
	var line := text.strip_edges()
	_input.clear()
	if line == "":
		return
	_history.append(line)
	if _history.size() > MAX_HISTORY:
		_history.pop_front()
	_history_pos = _history.size()
	run(line)


func _on_input_gui(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	match key.keycode:
		KEY_UP:
			_step_history(-1)
			_input.accept_event()
		KEY_DOWN:
			_step_history(1)
			_input.accept_event()
		KEY_TAB:
			_complete()
			_input.accept_event()


func _step_history(step: int) -> void:
	if _history.is_empty():
		return
	_history_pos = clampi(_history_pos + step, 0, _history.size())
	_input.text = "" if _history_pos >= _history.size() else _history[_history_pos]
	_input.caret_column = _input.text.length()


## Tab: дополняет имя команды (если подходит ровно одна), иначе показывает варианты.
func _complete() -> void:
	var typed := _input.text.strip_edges(true, false).to_lower()
	if typed == "" or typed.contains(" "):
		return
	var matches := PackedStringArray()
	for command in _ordered:
		if command.name.begins_with(typed):
			matches.append(command.name)
	if matches.size() == 1:
		_input.text = matches[0] + " "
		_input.caret_column = _input.text.length()
	elif matches.size() > 1:
		say("  ".join(matches), "aaaaaa")
