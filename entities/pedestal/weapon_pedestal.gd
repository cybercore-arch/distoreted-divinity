class_name WeaponPedestal
extends StaticBody2D
## Пьедестал с оружием, как в Isaac: коснулся — взял.
## Есть свободный слот — оружие забирается в него, пьедестал пустеет.
## Слоты заняты — заменяется активное оружие, а прежнее остаётся на пьедестале:
## можно пробовать всё по очереди.

const HALF: float = 10.0
const TRIGGER_MARGIN: float = 4.0
const NAME_RANGE: float = 56.0  ## с какого расстояния показывать название
const RARITY_COLORS: Dictionary = {
	WeaponData.Rarity.COMMON: Color(0.85, 0.85, 0.9),
	WeaponData.Rarity.UNCOMMON: Color(0.5, 0.85, 0.7),
	WeaponData.Rarity.RARE: Color(1.0, 0.8, 0.25),
}

var weapon: WeaponData

var _armed: bool = true  ## после обмена пьедестал снова срабатывает, только когда игрок отошёл
var _name_visible: bool = false


func _ready() -> void:
	add_to_group("low_obstacle")  # пули пролетают над пьедесталом
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(HALF, HALF) * 2.0
	shape.shape = rect
	add_child(shape)

	var trigger := Area2D.new()
	trigger.collision_layer = 0
	var trigger_shape := CollisionShape2D.new()
	var trigger_rect := RectangleShape2D.new()
	trigger_rect.size = Vector2(HALF + TRIGGER_MARGIN, HALF + TRIGGER_MARGIN) * 2.0
	trigger_shape.shape = trigger_rect
	trigger.add_child(trigger_shape)
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)
	add_child(trigger)


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var near := player != null and weapon != null and global_position.distance_to(player.global_position) < NAME_RANGE
	if near != _name_visible:
		_name_visible = near
		queue_redraw()


func _on_body_entered(body: Node) -> void:
	var player := body as Player
	if player == null or not _armed or weapon == null:
		return
	weapon = player.pick_up(weapon)  # прежнее оружие игрока (или null) остаётся на пьедестале
	_armed = false
	queue_redraw()


func _on_body_exited(body: Node) -> void:
	if body is Player:
		_armed = true


func _draw() -> void:
	draw_rect(Rect2(-HALF, -HALF, HALF * 2.0, HALF * 2.0), Color(0.22, 0.2, 0.3))
	draw_rect(Rect2(-HALF, -HALF, HALF * 2.0, HALF * 2.0), Color(0.45, 0.4, 0.6), false, 1.0)
	if weapon == null:
		return
	var rarity_color: Color = RARITY_COLORS.get(weapon.rarity, Color.WHITE)
	if weapon.icon != null:
		draw_texture_rect(weapon.icon, Rect2(-12.0, -12.0, 24.0, 24.0), false)
	else:
		var tint := weapon.primary.color if weapon.primary != null else Color.WHITE
		draw_colored_polygon(PackedVector2Array([Vector2(0, -7), Vector2(6, 0), Vector2(0, 7), Vector2(-6, 0)]), tint)
	draw_arc(Vector2.ZERO, HALF + 2.0, 0.0, TAU, 20, rarity_color, 1.0)
	if _name_visible:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-70.0, -HALF - 15.0), weapon.display_name, HORIZONTAL_ALIGNMENT_CENTER, 140.0, 8, rarity_color)
		draw_string(font, Vector2(-70.0, -HALF - 6.0), "Альт: " + weapon.alt_name, HORIZONTAL_ALIGNMENT_CENTER, 140.0, 8, Color(1, 1, 1, 0.7))
