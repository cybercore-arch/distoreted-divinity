class_name Hud
extends CanvasLayer
## Минимальный HUD. Слушает EventBus, ни на кого не ссылается напрямую.

var _label: Label
var _hint: Label
var _hp: String = ""
var _weapon: String = ""
var _dash: String = ""
var _alt_name: String = "Альт"
var _alt_fraction: float = 0.0


func _ready() -> void:
	_label = Label.new()
	_label.position = Vector2(20, 18)
	_label.add_theme_font_size_override("font_size", 10)
	add_child(_label)

	_hint = Label.new()
	_hint.position = Vector2(20, 240)
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.modulate = Color(1, 1, 1, 0.6)
	_hint.text = "дебаг: 1-5 оружие · Shift+1-6 враг · F заряд альта · C новая волна"
	add_child(_hint)

	EventBus.player_health_changed.connect(_on_health)
	EventBus.weapon_changed.connect(_on_weapon)
	EventBus.dash_cooldown_changed.connect(_on_dash)
	EventBus.alt_charge_changed.connect(_on_alt)
	_refresh()


func _on_health(current: int, maximum: int) -> void:
	_hp = "HP %d/%d" % [current, maximum]
	_refresh()


func _on_weapon(weapon: WeaponData) -> void:
	_weapon = weapon.display_name
	_alt_name = weapon.alt_name
	_refresh()


func _on_dash(remaining: float, _total: float) -> void:
	var text := "Рывок: готов" if remaining <= 0.0 else "Рывок: %.1f" % remaining
	if text != _dash:
		_dash = text
		_refresh()


func _on_alt(fraction: float) -> void:
	_alt_fraction = fraction
	_refresh()


func _refresh() -> void:
	var alt_text := "%s: %d%%" % [_alt_name, int(_alt_fraction * 100.0)]
	if _alt_fraction >= 1.0:
		alt_text = "%s: ГОТОВ (E)" % _alt_name
	_label.text = "%s  |  %s  |  %s  |  %s" % [_hp, _weapon, _dash, alt_text]
