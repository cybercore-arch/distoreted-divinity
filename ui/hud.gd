class_name Hud
extends CanvasLayer
## Минимальный HUD. Слушает EventBus, ни на кого не ссылается напрямую.

var _label: Label
var _hp: String = ""
var _weapon: String = ""
var _dash: String = ""


func _ready() -> void:
	_label = Label.new()
	_label.position = Vector2(20, 18)
	_label.add_theme_font_size_override("font_size", 10)
	add_child(_label)
	EventBus.player_health_changed.connect(_on_health)
	EventBus.weapon_changed.connect(_on_weapon)
	EventBus.dash_cooldown_changed.connect(_on_dash)
	_refresh()


func _on_health(current: int, maximum: int) -> void:
	_hp = "HP %d/%d" % [current, maximum]
	_refresh()


func _on_weapon(weapon: WeaponData) -> void:
	_weapon = weapon.display_name
	_refresh()


func _on_dash(remaining: float, _total: float) -> void:
	var text := "Рывок: готов" if remaining <= 0.0 else "Рывок: %.1f" % remaining
	if text != _dash:
		_dash = text
		_refresh()


func _refresh() -> void:
	_label.text = "%s   |   %s   |   %s" % [_hp, _weapon, _dash]
