class_name Shockwave
extends Node2D
## Взрывная волна (артефакт Last Rite): расширяющееся кольцо бьёт каждого врага один раз
## и стирает все вражеские пули, которых коснулось.

const DURATION: float = 0.55
const MAX_RADIUS: float = 520.0

var damage: int = 40

var _age: float = 0.0
var _hit: Array[Node] = []


func _ready() -> void:
	add_to_group("transient")


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	var radius := MAX_RADIUS * _age / DURATION
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy != null and not _hit.has(enemy) and global_position.distance_to(enemy.global_position) <= radius:
			_hit.append(enemy)
			enemy.take_damage(damage)
	for node in get_tree().get_nodes_in_group("transient"):
		var bullet := node as Projectile
		if bullet != null and bullet.team == "enemy" and global_position.distance_to(bullet.global_position) <= radius:
			bullet.queue_free()
	queue_redraw()


func _draw() -> void:
	var t := _age / DURATION
	var radius := MAX_RADIUS * t
	var fade := 1.0 - t
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 0.9, 0.5, 0.8 * fade), 3.0)
	draw_arc(Vector2.ZERO, maxf(0.0, radius - 8.0), 0.0, TAU, 64, Color(1.0, 0.7, 0.3, 0.4 * fade), 2.0)
