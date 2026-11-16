class_name Player
extends CharacterBody2D
## Игрок: WASD — движение, стрелки — стрельба, Q — смена оружия,
## E — альт (когда шкала заряда полная), пробел — рывок (неуязвимость + перезарядка).

const ALT_MAX: float = 100.0
const MAX_SPEED_MULT: float = 1.5  ## ускорения не складываются и не превышают это значение

@export var move_speed: float = 120.0
@export var dash_speed: float = 340.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 5.0
@export var max_health: int = 100
@export var hitbox_radius: float = 6.0
@export var sprite: Texture2D  ## сюда позже ляжет спрайт 32x32
@export var weapons: Array[WeaponData] = []

var health: Health
var invulnerable: bool = false
var alt_charge: float = 0.0

var _slot: int = 0
var _facing: Vector2 = Vector2.DOWN
var _dash_dir: Vector2 = Vector2.ZERO
var _dash_left: float = 0.0
var _dash_cd_left: float = 0.0
var _primary_cd: float = 0.0
var _boost_mult: float = 1.0
var _boost_left: float = 0.0


func _ready() -> void:
	add_to_group("player")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = hitbox_radius
	shape.shape = circle
	add_child(shape)

	health = Health.new()
	add_child(health)
	health.changed.connect(func(c: int, m: int) -> void: EventBus.player_health_changed.emit(c, m))
	health.died.connect(func() -> void: get_tree().reload_current_scene.call_deferred())
	health.setup(max_health)

	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	EventBus.alt_charge_changed.emit(0.0)
	if not weapons.is_empty():
		EventBus.weapon_changed.emit(weapons[_slot])


func _physics_process(delta: float) -> void:
	_primary_cd = maxf(0.0, _primary_cd - delta)
	_dash_cd_left = maxf(0.0, _dash_cd_left - delta)
	EventBus.dash_cooldown_changed.emit(_dash_cd_left, dash_cooldown)

	if _boost_left > 0.0:
		_boost_left -= delta
		if _boost_left <= 0.0:
			_boost_mult = 1.0

	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _dash_left > 0.0:
		_dash_left -= delta
		velocity = _dash_dir * dash_speed
		if _dash_left <= 0.0:
			invulnerable = false
	else:
		velocity = move * move_speed * _boost_mult
		if Input.is_action_just_pressed("dash") and _dash_cd_left <= 0.0:
			_start_dash(move)
	move_and_slide()

	if Input.is_action_just_pressed("swap_weapon") and weapons.size() > 1:
		_slot = (_slot + 1) % weapons.size()
		_primary_cd = 0.0
		EventBus.weapon_changed.emit(weapons[_slot])
	_handle_weapons(move)
	queue_redraw()


func take_damage(amount: int) -> void:
	if invulnerable:
		return
	health.damage(amount)


## Ускорение не стакается: берётся сильнейшее, максимум MAX_SPEED_MULT.
func apply_speed_boost(mult: float, duration: float) -> void:
	mult = minf(mult, MAX_SPEED_MULT)
	if _boost_left > 0.0 and mult < _boost_mult:
		return
	_boost_mult = mult
	_boost_left = maxf(_boost_left, duration)


func add_alt_charge(amount: float) -> void:
	alt_charge = clampf(alt_charge + amount, 0.0, ALT_MAX)
	EventBus.alt_charge_changed.emit(alt_charge / ALT_MAX)


## Подменяет оружие в активном слоте (нужно для дебага и подбора предметов).
func equip(weapon: WeaponData) -> void:
	if weapons.is_empty():
		weapons.append(weapon)
	else:
		weapons[_slot] = weapon
	_primary_cd = 0.0
	EventBus.weapon_changed.emit(weapon)


func _on_enemy_damaged(amount: int) -> void:
	if weapons.is_empty():
		return
	var needed := maxf(1.0, weapons[_slot].alt_damage_needed)
	add_alt_charge(float(amount) / needed * ALT_MAX)


func _start_dash(move: Vector2) -> void:
	_dash_dir = move.normalized() if move != Vector2.ZERO else _facing
	_dash_left = dash_duration
	_dash_cd_left = dash_cooldown
	invulnerable = true


func _handle_weapons(move: Vector2) -> void:
	if weapons.is_empty():
		return
	var weapon := weapons[_slot]
	var aim := Input.get_vector("shoot_left", "shoot_right", "shoot_up", "shoot_down")
	if aim != Vector2.ZERO:
		_facing = aim.normalized()
	elif move != Vector2.ZERO:
		_facing = move.normalized()

	if aim != Vector2.ZERO and _primary_cd <= 0.0 and weapon.primary != null:
		_use(weapon.primary, _facing)
		_primary_cd = 1.0 / weapon.primary.fire_rate
	if Input.is_action_just_pressed("alt_fire") and alt_charge >= ALT_MAX and weapon.alt != null:
		_use(weapon.alt, _facing)
		alt_charge = 0.0
		EventBus.alt_charge_changed.emit(0.0)


func _use(mode: FireMode, dir: Vector2) -> void:
	match mode.kind:
		FireMode.Kind.PROJECTILE:
			_fire_projectiles(mode, dir)
		FireMode.Kind.MELEE:
			var strike := MeleeStrike.new()
			strike.setup(self, dir, mode)
			get_tree().current_scene.add_child(strike)
		FireMode.Kind.ZONE:
			var zone := DamageZone.new()
			zone.setup(global_position, mode)
			get_tree().current_scene.add_child(zone)
	if mode.speed_boost > 1.0:
		apply_speed_boost(mode.speed_boost, mode.speed_boost_duration)


func _fire_projectiles(mode: FireMode, dir: Vector2) -> void:
	var half := mode.spread_degrees * 0.5
	for i in mode.pellets:
		var offset := 0.0
		if mode.pellets > 1:
			if mode.spread_degrees >= 360.0:
				offset = 360.0 * float(i) / float(mode.pellets)
			else:
				offset = lerpf(-half, half, float(i) / float(mode.pellets - 1))
		else:
			offset = randf_range(-half, half)
		var bullet := Projectile.new()
		bullet.setup(global_position, dir.rotated(deg_to_rad(offset)) * mode.projectile_speed, mode.damage, "player", mode.color, mode.projectile_lifetime, mode.projectile_radius)
		bullet.pierce = mode.pierce
		bullet.bounces_left = mode.bounces
		bullet.homing = mode.homing_degrees
		bullet.visual = mode.projectile_shape
		bullet.length = mode.projectile_length
		get_tree().current_scene.add_child(bullet)


func _draw() -> void:
	var tint := Color(1, 1, 1, 0.45) if invulnerable else Color.WHITE
	if sprite != null:
		draw_texture(sprite, -sprite.get_size() / 2.0, tint)
	else:
		draw_rect(Rect2(-8, -8, 16, 16), Color(0.95, 0.85, 0.4) * tint)
		draw_line(Vector2.ZERO, _facing * 12.0, Color.WHITE, 2.0)
	if alt_charge >= ALT_MAX:
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, Color(1.0, 0.9, 0.4), 1.0)
