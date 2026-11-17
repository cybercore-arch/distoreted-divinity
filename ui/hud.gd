class_name Hud
extends CanvasLayer
## Минимальный HUD. Слушает EventBus, ни на кого не ссылается напрямую.

var _status: Label
var _loadout: Label
var _artifacts: Label
var _room: Label
var _hint: Label
var _hp: String = ""
var _dash: String = ""
var _slots_text: String = ""
var _alt_name: String = "Альт"
var _alt_fraction: float = 0.0


func _ready() -> void:
	_status = _make_label(Vector2(20, 18), 10, 1.0)
	_loadout = _make_label(Vector2(20, 30), 10, 1.0)
	_artifacts = _make_label(Vector2(20, 42), 8, 0.8)
	_room = _make_label(Vector2(20, 234), 8, 0.8)
	_hint = _make_label(Vector2(20, 245), 8, 0.6)
	_hint.text = "консоль: ` (ё) · дебаг: F заряд альта · C сброс врагов"

	EventBus.player_health_changed.connect(_on_health)
	EventBus.loadout_changed.connect(_on_loadout)
	EventBus.artifacts_changed.connect(_on_artifacts)
	EventBus.dash_cooldown_changed.connect(_on_dash)
	EventBus.alt_charge_changed.connect(_on_alt)
	EventBus.room_changed.connect(func(title: String) -> void: _room.text = title)
	_refresh()


func _make_label(pos: Vector2, font_size: int, alpha: float) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = Color(1, 1, 1, alpha)
	add_child(label)
	return label


func _on_health(current: int, maximum: int) -> void:
	_hp = "HP %d/%d" % [current, maximum]
	_refresh()


## Слоты оружия: активный в скобках, свободные слоты — прочерк.
func _on_loadout(weapons: Array, active_slot: int, limit: int) -> void:
	var parts := PackedStringArray()
	for i in limit:
		var text := "—"
		if i < weapons.size():
			text = (weapons[i] as WeaponData).display_name
		parts.append(("[%s]" % text) if i == active_slot else text)
	_slots_text = "  |  ".join(parts)
	if active_slot < weapons.size():
		_alt_name = (weapons[active_slot] as WeaponData).alt_name
	_refresh()


func _on_artifacts(artifacts: Array) -> void:
	if artifacts.is_empty():
		_artifacts.text = ""
		return
	var names := PackedStringArray()
	for artifact in artifacts:
		names.append((artifact as ArtifactData).display_name)
	_artifacts.text = "Артефакты: " + ", ".join(names)


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
	_status.text = "%s  |  %s  |  %s" % [_hp, _dash, alt_text]
	_loadout.text = _slots_text
