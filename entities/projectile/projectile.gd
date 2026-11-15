class_name Projectile
extends Area2D
## Универсальная пуля. team = "player" или "enemy": пуля игнорирует свою команду.

var velocity: Vector2 = Vector2.ZERO
var damage: int = 1
var team: String = "player"
var color: Color = Color.WHITE
var radius: float = 3.0
var lifetime: float = 1.0


func setup(pos: Vector2, vel: Vector2, dmg: int, p_team: String, p_color: Color, p_lifetime: float, p_radius: float) -> void:
	position = pos
	velocity = vel
	damage = dmg
	team = p_team
	color = p_color
	lifetime = p_lifetime
	radius = p_radius


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(team):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
