class_name Player
extends CharacterBody2D
## Игрок: WASD — движение, стрелки — стрельба, Q — смена оружия,
## E — альт (когда шкала заряда полная), пробел — рывок (неуязвимость + перезарядка).
## Оружие берётся с пьедесталов через pick_up(), число слотов ограничено get_weapon_limit().
## Все числа (урон, скорость, здоровье…) идут через stats (PlayerStats): база здесь, правки — от артефактов.

const ALT_MAX: float = 100.0
const MAX_SPEED_MULT: float = 1.5  ## ускорения от оружия не складываются и не превышают это значение
const KILL_WINDOW: float = 2.0  ## сколько секунд после убийства действует условие RECENT_KILL
const FOCUS_HOMING_DEGREES: float = 240.0  ## самонаведение от Curse of Focus
const RICOCHET_BOUNCES: int = 2  ## рикошеты от Mirror Scale
const LAST_STAND_GRACE: float = 2.0  ## неуязвимость после Last Rite

@export var move_speed: float = 120.0
@export var dash_speed: float = 340.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 5.0
@export var max_health: int = 100
@export var hitbox_radius: float = 6.0
@export var base_weapon_limit: int = 2  ## базовое число слотов оружия; артефакты прибавляют свои (get_weapon_limit)
@export var sprite: Texture2D  ## сюда позже ляжет спрайт 32x32
@export var weapons: Array[WeaponData] = []

var health: Health
var stats := PlayerStats.new()
var invulnerable: bool = false
var alt_charge: float = 0.0
var artifacts: Array[ArtifactData] = []

var _slot: int = 0
var _facing: Vector2 = Vector2.DOWN
var _dash_dir: Vector2 = Vector2.ZERO
var _dash_left: float = 0.0
var _dash_cd_left: float = 0.0
var _dash_charges: int = 0  ## сколько рывков ещё можно сделать, пока идёт перезарядка (DOUBLE_DASH)
var _primary_cd: float = 0.0
var _boost_mult: float = 1.0
var _boost_left: float = 0.0
var _slow_mult: float = 1.0
var _slow_left: float = 0.0
var _kill_left: float = 0.0
var _grace_left: float = 0.0
var _last_stand_used: bool = false
var _effects: ArtifactEffects
var _layers: Array[ArtifactData] = []  ## артефакты со слоем внешнего вида, по порядку отрисовки
var _stats_key: String = ""


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

	_effects = ArtifactEffects.new()
	add_child(_effects)
	_effects.setup(self)

	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	DebugState.flag_changed.connect(_on_debug_flag)
	EventBus.alt_charge_changed.emit(0.0)
	_on_artifacts_changed()


func _physics_process(delta: float) -> void:
	_primary_cd = maxf(0.0, _primary_cd - delta)
	_dash_cd_left = maxf(0.0, _dash_cd_left - delta)
	_kill_left = maxf(0.0, _kill_left - delta)
	_grace_left = maxf(0.0, _grace_left - delta)
	_tick_boosts(delta)
	_refresh_conditions()
	_emit_dash_state()

	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var was_dashing := _dash_left > 0.0
	if was_dashing:
		_dash_left -= delta
		velocity = _dash_dir * dash_speed
		if _dash_left <= 0.0:
			invulnerable = false
	else:
		velocity = move * stats.final(StatModifier.Stat.MOVE_SPEED, move_speed) * _boost_mult * _slow_mult
		if Input.is_action_just_pressed("dash") and _can_dash():
			_start_dash(move)
	move_and_slide()
	if was_dashing:
		_effects.dash_step(global_position)

	if Input.is_action_just_pressed("swap_weapon") and weapons.size() > 1:
		_slot = (_slot + 1) % weapons.size()
		_primary_cd = 0.0
		_emit_loadout()
	_handle_weapons(move)
	queue_redraw()


func take_damage(amount: int) -> void:
	if invulnerable or _grace_left > 0.0 or DebugState.infhp:
		return
	amount = stats.scale_int(amount, StatModifier.Stat.DAMAGE_TAKEN)
	if stats.has_perk(ArtifactData.Perk.LAST_STAND) and not _last_stand_used and amount >= health.current:
		_last_stand_used = true
		health.damage(health.current - 1)
		_grace_left = LAST_STAND_GRACE
		_effects.last_stand(global_position)
		return
	health.damage(amount)


## Ускорение не стакается: берётся сильнейшее, максимум MAX_SPEED_MULT.
func apply_speed_boost(mult: float, duration: float) -> void:
	mult = minf(mult, MAX_SPEED_MULT)
	if _boost_left > 0.0 and mult < _boost_mult:
		return
	_boost_mult = mult
	_boost_left = maxf(_boost_left, duration)


## Замедление от врагов и поверхностей. Артефакты с SLOW_IMMUNE его игнорируют.
func apply_slow(mult: float, duration: float) -> void:
	if stats.has_perk(ArtifactData.Perk.SLOW_IMMUNE):
		return
	_slow_mult = minf(_slow_mult if _slow_left > 0.0 else 1.0, mult)
	_slow_left = maxf(_slow_left, duration)


func add_alt_charge(amount: float) -> void:
	alt_charge = clampf(alt_charge + amount, 0.0, ALT_MAX)
	EventBus.alt_charge_changed.emit(alt_charge / ALT_MAX)


## Подбор оружия. Есть свободный слот — оружие занимает его и становится активным (вернёт null).
## Слоты заняты — заменяет активное, а прежнее возвращает (пьедестал забирает его себе).
func pick_up(weapon: WeaponData) -> WeaponData:
	var leftover: WeaponData = null
	if weapons.size() < get_weapon_limit():
		weapons.append(weapon)
		_slot = weapons.size() - 1
	else:
		leftover = weapons[_slot]
		weapons[_slot] = weapon
	_primary_cd = 0.0
	_emit_loadout()
	return leftover


## Мгновенно переставляет игрока (смена комнаты).
func teleport(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO


## Сколько оружия можно держать сейчас: база плюс бонусы артефактов.
func get_weapon_limit() -> int:
	return maxi(1, roundi(stats.final(StatModifier.Stat.WEAPON_SLOTS, float(base_weapon_limit))))


func add_artifact(artifact: ArtifactData) -> void:
	artifacts.append(artifact)
	_on_artifacts_changed()


## Убирает один экземпляр артефакта. Вернёт false, если такого нет.
func remove_artifact(artifact: ArtifactData) -> bool:
	var index := artifacts.find(artifact)
	if index < 0:
		return false
	artifacts.remove_at(index)
	_on_artifacts_changed()
	return true


func clear_artifacts() -> void:
	artifacts.clear()
	_on_artifacts_changed()


# --- Пересчёт характеристик -------------------------------------------------

func _on_artifacts_changed() -> void:
	stats.artifacts = artifacts
	if not stats.has_perk(ArtifactData.Perk.LAST_STAND):
		_last_stand_used = false  # сняли и снова взяли — защита снова доступна
	health.set_max(roundi(stats.final(StatModifier.Stat.MAX_HEALTH, float(max_health))))
	while weapons.size() > get_weapon_limit():  # лимит упал — лишнее оружие пропадает с конца
		weapons.pop_back()
	_slot = clampi(_slot, 0, maxi(0, weapons.size() - 1))
	_layers = artifacts.filter(func(a: ArtifactData) -> bool: return a.body_layer != null)
	_layers.sort_custom(func(a: ArtifactData, b: ArtifactData) -> bool: return a.layer_order < b.layer_order)
	_stats_key = ""
	_refresh_conditions()
	EventBus.artifacts_changed.emit(artifacts)
	_emit_loadout()


## Условные правки (здоровье выше 80%, недавнее убийство) зависят от состояния: обновляем панель при смене.
func _refresh_conditions() -> void:
	stats.health_fraction = float(health.current) / float(maxi(1, health.max_health))
	stats.recent_kill = _kill_left > 0.0
	var key := "%s|%s|%d" % [stats.health_fraction > PlayerStats.HIGH_HEALTH, stats.recent_kill, artifacts.size()]
	if key == _stats_key:
		return
	_stats_key = key
	EventBus.stats_changed.emit(stats.describe(dash_cooldown))


func _tick_boosts(delta: float) -> void:
	if _boost_left > 0.0:
		_boost_left -= delta
		if _boost_left <= 0.0:
			_boost_mult = 1.0
	if _slow_left > 0.0:
		_slow_left -= delta
		if _slow_left <= 0.0:
			_slow_mult = 1.0


func _on_debug_flag(flag: String, on: bool) -> void:
	if flag == "infalt" and on:
		add_alt_charge(ALT_MAX)


func _emit_loadout() -> void:
	EventBus.loadout_changed.emit(weapons, _slot, get_weapon_limit())


func _on_enemy_damaged(amount: int) -> void:
	if weapons.is_empty():
		return
	var needed := maxf(1.0, weapons[_slot].alt_damage_needed)
	add_alt_charge(float(amount) / needed * ALT_MAX)


func _on_enemy_killed(_enemy: Node) -> void:
	_kill_left = KILL_WINDOW


# --- Рывок ------------------------------------------------------------------

func _max_dash_charges() -> int:
	return 2 if stats.has_perk(ArtifactData.Perk.DOUBLE_DASH) else 1


## Рывок доступен, когда перезарядка прошла или остались рывки от DOUBLE_DASH в текущем окне перезарядки.
func _can_dash() -> bool:
	return _dash_cd_left <= 0.0 or _dash_charges > 0


func _start_dash(move: Vector2) -> void:
	_dash_dir = move.normalized() if move != Vector2.ZERO else _facing
	_dash_left = dash_duration
	if _dash_cd_left <= 0.0:
		_dash_charges = _max_dash_charges() - 1
		var cooldown := maxf(PlayerStats.MIN_DASH_COOLDOWN, stats.final(StatModifier.Stat.DASH_COOLDOWN, dash_cooldown))
		_dash_cd_left = 0.0 if DebugState.infdash else cooldown
	else:
		_dash_charges -= 1
	invulnerable = true
	_effects.dash_started(global_position)


func _emit_dash_state() -> void:
	var total := maxf(PlayerStats.MIN_DASH_COOLDOWN, stats.final(StatModifier.Stat.DASH_COOLDOWN, dash_cooldown))
	var charges := _max_dash_charges() if _dash_cd_left <= 0.0 else _dash_charges
	EventBus.dash_cooldown_changed.emit(_dash_cd_left, total, charges)


# --- Оружие -----------------------------------------------------------------

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
		_primary_cd = 1.0 / (weapon.primary.fire_rate * maxf(0.1, stats.final(StatModifier.Stat.FIRE_RATE, 1.0)))
	if Input.is_action_just_pressed("alt_fire") and alt_charge >= ALT_MAX and weapon.alt != null:
		_use(weapon.alt, _facing)
		if not DebugState.infalt:
			alt_charge = 0.0
			EventBus.alt_charge_changed.emit(0.0)


## Применяет режим оружия (основной или альт): выпускает пули, удар или зону.
func _use(mode: FireMode, dir: Vector2) -> void:
	match mode.kind:
		FireMode.Kind.PROJECTILE:
			_fire_projectiles(mode, dir)
		FireMode.Kind.MELEE:
			var strike := MeleeStrike.new()
			strike.setup(self, dir, mode)
			strike.damage = stats.scale_int(mode.damage, StatModifier.Stat.DAMAGE)
			strike.reach = mode.melee_reach * stats.final(StatModifier.Stat.RANGE, 1.0)
			strike.reverse = stats.has_perk(ArtifactData.Perk.HINDSIGHT)
			get_tree().current_scene.add_child(strike)
		FireMode.Kind.ZONE:
			var zone := DamageZone.new()
			zone.setup(global_position, mode)
			zone.damage_mult = stats.final(StatModifier.Stat.DAMAGE, 1.0)
			get_tree().current_scene.add_child(zone)
	if mode.speed_boost > 1.0:
		apply_speed_boost(mode.speed_boost, mode.speed_boost_duration)


func _fire_projectiles(mode: FireMode, dir: Vector2) -> void:
	var shot_speed := stats.final(StatModifier.Stat.SHOT_SPEED, 1.0)
	var speed := mode.projectile_speed * shot_speed
	# Дальность не зависит от скорости пули: быстрая пуля живёт пропорционально меньше.
	var lifetime := mode.projectile_lifetime * stats.final(StatModifier.Stat.RANGE, 1.0) / maxf(0.1, shot_speed)
	var homing := mode.homing_degrees
	if stats.has_perk(ArtifactData.Perk.HOMING):
		homing = maxf(homing, FOCUS_HOMING_DEGREES)
	var bounces := mode.bounces
	if stats.has_perk(ArtifactData.Perk.RICOCHET):
		bounces += RICOCHET_BOUNCES
	var hindsight := stats.has_perk(ArtifactData.Perk.HINDSIGHT)

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
		var shot_dir := dir.rotated(deg_to_rad(offset))
		var start := global_position
		var velocity_out := shot_dir * speed
		var life := lifetime
		if hindsight:
			# Пуля рождается там, где закончился бы её путь (или упёрлась бы в стену), и летит к игроку.
			start = _path_end(shot_dir, speed * lifetime)
			velocity_out = -shot_dir * speed
			life = maxf(0.02, start.distance_to(global_position) / speed)
		var bullet := Projectile.new()
		bullet.setup(start, velocity_out, stats.scale_int(mode.damage, StatModifier.Stat.DAMAGE), "player", mode.color, life, mode.projectile_radius)
		bullet.pierce = mode.pierce
		bullet.bounces_left = bounces
		bullet.homing = homing
		bullet.visual = mode.projectile_shape
		bullet.length = mode.projectile_length
		get_tree().current_scene.add_child(bullet)


## Где закончится путь пули длиной distance из позиции игрока: у стены или в конце дальности.
func _path_end(dir: Vector2, distance: float) -> Vector2:
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + dir * distance, Projectile.WALL_MASK)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return global_position + dir * distance
	return (hit["position"] as Vector2) - dir * 2.0


# --- Отрисовка --------------------------------------------------------------

func _draw() -> void:
	var dimmed := invulnerable or _grace_left > 0.0
	var tint := Color(1, 1, 1, 0.45) if dimmed else Color.WHITE
	if sprite != null:
		draw_texture(sprite, -sprite.get_size() / 2.0, tint)
	else:
		draw_rect(Rect2(-8, -8, 16, 16), Color(0.95, 0.85, 0.4) * tint)
		draw_line(Vector2.ZERO, _facing * 12.0, Color.WHITE, 2.0)
	for artifact in _layers:  # слои артефактов поверх тела: так предметы меняют внешний вид
		draw_texture(artifact.body_layer, -artifact.body_layer.get_size() / 2.0, tint)
	if alt_charge >= ALT_MAX:
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, Color(1.0, 0.9, 0.4), 1.0)
