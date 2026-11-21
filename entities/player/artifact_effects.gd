class_name ArtifactEffects
extends Node
## Исполняет «живые» механики артефактов, которые не сводятся к числам (ArtifactData.Perk):
## осколки при убийстве, огненный след рывка, взрывная волна Last Rite.
## Числовые правки и условия считает PlayerStats, пули-перки (самонаведение, рикошет, Hindsight) — Player.

const SHARD_COUNT: int = 8
const SHARD_SPEED: float = 210.0
const SHARD_LIFETIME: float = 0.45
const SHARD_DAMAGE: int = 5
const SHARD_COLOR := Color(1.0, 0.85, 0.5)
const TRAIL_STEP: float = 10.0  ## через сколько пикселей рывка оставляется лужа
const LAST_STAND_DAMAGE: int = 40

var _player: Player
var _trail_mode: FireMode
var _last_trail_pos: Vector2 = Vector2.ZERO


func setup(player: Player) -> void:
	_player = player
	EventBus.enemy_killed.connect(_on_enemy_killed)
	_trail_mode = FireMode.new()
	_trail_mode.kind = FireMode.Kind.ZONE
	_trail_mode.damage = 3
	_trail_mode.zone_radius = 13.0
	_trail_mode.zone_duration = 2.5
	_trail_mode.zone_tick = 0.2
	_trail_mode.color = Color(1.0, 0.45, 0.1)


## Начало рывка: след начинается с текущей точки.
func dash_started(pos: Vector2) -> void:
	_last_trail_pos = pos
	_drop_trail(pos)


## Каждый кадр рывка: оставляет лужи через равные промежутки.
func dash_step(pos: Vector2) -> void:
	if pos.distance_to(_last_trail_pos) >= TRAIL_STEP:
		_drop_trail(pos)


## Смертельный удар пережит: волна вокруг игрока.
func last_stand(origin: Vector2) -> void:
	var wave := Shockwave.new()
	wave.damage = LAST_STAND_DAMAGE
	wave.position = origin
	_add_to_scene.call_deferred(wave)


func _drop_trail(pos: Vector2) -> void:
	if not _player.stats.has_perk(ArtifactData.Perk.EMBER_TRAIL):
		return
	_last_trail_pos = pos
	var zone := DamageZone.new()
	zone.setup(pos, _trail_mode)
	zone.damage_mult = _player.stats.final(StatModifier.Stat.DAMAGE, 1.0)
	_add_to_scene.call_deferred(zone)  # Area2D в дерево — только отложенно


func _on_enemy_killed(enemy: Node) -> void:
	if not _player.stats.has_perk(ArtifactData.Perk.SHARD_BURST):
		return
	var origin := (enemy as Node2D).global_position
	_spawn_shards.call_deferred(origin)  # убийство происходит внутри физического колбэка


func _spawn_shards(origin: Vector2) -> void:
	var damage := _player.stats.scale_int(SHARD_DAMAGE, StatModifier.Stat.DAMAGE)
	var phase := randf() * TAU
	for i in SHARD_COUNT:
		var bullet := Projectile.new()
		var dir := Vector2.from_angle(phase + TAU * float(i) / float(SHARD_COUNT))
		bullet.setup(origin, dir * SHARD_SPEED, damage, "player", SHARD_COLOR, SHARD_LIFETIME, 2.5)
		_add_to_scene(bullet)


func _add_to_scene(node: Node) -> void:
	var scene := get_tree().current_scene
	if scene != null:
		scene.add_child(node)
