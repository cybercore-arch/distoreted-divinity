class_name Pedestal
extends StaticBody2D
## Базовый пьедестал, как в Isaac: коснулся — взял. Общая часть для оружия и артефактов:
## физика, срабатывание при касании, показ названия вблизи. Наследник отвечает за предмет:
## _has_item(), _take(player), _accent(), _draw_icon(), _title(), _details().
## После срабатывания пьедестал снова готов, только когда игрок отошёл (нужно для обмена оружия).

const HALF: float = 10.0
const TRIGGER_MARGIN: float = 4.0
const NAME_RANGE: float = 56.0  ## с какого расстояния показывать название
const INFO_WIDTH: float = 170.0
const ARM_DELAY: float = 0.1  ## сразу после создания комнаты пьедестал не срабатывает: игрока ещё переставляют на место входа

var _armed: bool = false
var _name_visible: bool = false
var _trigger: Area2D


func _ready() -> void:
	add_to_group("low_obstacle")  # пули пролетают над пьедесталом
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(HALF, HALF) * 2.0
	shape.shape = rect
	add_child(shape)

	var trigger := Area2D.new()
	_trigger = trigger
	trigger.collision_layer = 0
	var trigger_shape := CollisionShape2D.new()
	var trigger_rect := RectangleShape2D.new()
	trigger_rect.size = Vector2(HALF + TRIGGER_MARGIN, HALF + TRIGGER_MARGIN) * 2.0
	trigger_shape.shape = trigger_rect
	trigger.add_child(trigger_shape)
	trigger.body_entered.connect(_on_body_entered)
	trigger.body_exited.connect(_on_body_exited)
	add_child(trigger)
	get_tree().create_timer(ARM_DELAY).timeout.connect(_arm)


## Взводится, если игрок не стоит прямо на пьедестале; иначе ждёт, пока тот отойдёт.
func _arm() -> void:
	if not is_inside_tree():
		return
	_armed = not _trigger.get_overlapping_bodies().any(func(body: Node) -> bool: return body is Player)


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var near := player != null and _has_item() and global_position.distance_to(player.global_position) < NAME_RANGE
	if near != _name_visible:
		_name_visible = near
		queue_redraw()


func _on_body_entered(body: Node) -> void:
	var player := body as Player
	if player == null or not _armed or not _has_item():
		return
	_take(player)
	_armed = false
	queue_redraw()


func _on_body_exited(body: Node) -> void:
	if body is Player:
		_armed = true


func _draw() -> void:
	draw_rect(Rect2(-HALF, -HALF, HALF * 2.0, HALF * 2.0), Color(0.22, 0.2, 0.3))
	draw_rect(Rect2(-HALF, -HALF, HALF * 2.0, HALF * 2.0), Color(0.45, 0.4, 0.6), false, 1.0)
	if not _has_item():
		return
	_draw_icon()
	draw_arc(Vector2.ZERO, HALF + 2.0, 0.0, TAU, 20, _accent(), 1.0)
	if _name_visible:
		var font := ThemeDB.fallback_font
		var details := _details()
		var lines := 1 + details.count("\n") + (1 if details.length() > 36 else 0)  # грубо: сколько строк займут детали
		var top := -HALF - 14.0 - 9.0 * float(mini(lines, 3))
		draw_string(font, Vector2(-INFO_WIDTH * 0.5, top), _title(), HORIZONTAL_ALIGNMENT_CENTER, INFO_WIDTH, 8, _accent())
		draw_multiline_string(font, Vector2(-INFO_WIDTH * 0.5, top + 9.0), details, HORIZONTAL_ALIGNMENT_CENTER, INFO_WIDTH, 8, 3, Color(1, 1, 1, 0.7))


# --- Переопределяется наследниками -------------------------------------------

func _has_item() -> bool:
	return false


## Игрок коснулся пьедестала: отдать ему предмет и обновить своё содержимое.
func _take(_player: Player) -> void:
	pass


func _accent() -> Color:
	return Color.WHITE


func _title() -> String:
	return ""


func _details() -> String:
	return ""


func _draw_icon() -> void:
	pass
