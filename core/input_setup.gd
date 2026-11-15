extends Node
## Регистрирует действия ввода кодом, чтобы раскладка жила в одном месте.
## WASD — движение, стрелки — стрельба, Q — смена оружия, E — альт-огонь, пробел — рывок.

const BINDINGS := {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_up": KEY_W,
	"move_down": KEY_S,
	"shoot_left": KEY_LEFT,
	"shoot_right": KEY_RIGHT,
	"shoot_up": KEY_UP,
	"shoot_down": KEY_DOWN,
	"swap_weapon": KEY_Q,
	"alt_fire": KEY_E,
	"dash": KEY_SPACE,
}


func _ready() -> void:
	for action in BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = BINDINGS[action] as Key
		InputMap.action_add_event(action, event)
