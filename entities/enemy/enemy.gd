class_name Enemy
extends CharacterBody2D
## Враг, целиком описанный EnemyData. Поведение выбирается полем behavior:
## RANGED (атаки паттернами пуль), CHARGE (бежит напролом), LUNGE (рывок с предупреждением).

enum State { MOVE, WINDUP, BURST, LUNGING, REST }

@export var data: EnemyData

var health: Health

var _state: State = State.MOVE
var _state_time: float = 0.0
var _cooldown: float = 1.0
var _contact_cd: float = 0.0
var _flash: float = 0.0
var _aim: Vector2 = Vector2.DOWN
var _attack: BulletPattern  ## текущая атака (RANGED)
var _attack_index: int = 0
var _runner: PatternRunner
var _player: Node2D


func _ready() -> void:
	add_to_group("enemy")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = data.radius
	shape.shape = circle
	add_child(shape)

	health = Health.new()
	add_child(health)
	health.setup(data.max_health)
	health.died.connect(_on_died)

	if data.behavior == EnemyData.Behavior.RANGED:
		_runner = PatternRunner.new()
		_runner.team = "enemy"
		_runner.finished.connect(_on_attack_finished)
		add_child(_runner)

	_cooldown = randf_range(0.4, maxf(0.5, data.fire_interval))


func take_damage(amount: int) -> void:
	if DebugState.onehit:
		amount = health.current
	var dealt := mini(amount, health.current)
	health.damage(amount)
	_flash = 0.08
	if dealt > 0:
		EventBus.enemy_damaged.emit(dealt)


func _physics_process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_contact_cd = maxf(0.0, _contact_cd - delta)
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player == null:
		return

	var to_player := _player.global_position - global_position
	match data.behavior:
		EnemyData.Behavior.CHARGE:
			velocity = to_player.normalized() * data.move_speed
		EnemyData.Behavior.RANGED:
			_tick_ranged(delta, to_player)
		EnemyData.Behavior.LUNGE:
			_tick_lunge(delta, to_player)
	move_and_slide()

	_check_contact()
	queue_redraw()


# --- RANGED -----------------------------------------------------------------

func _tick_ranged(delta: float, to_player: Vector2) -> void:
	match _state:
		State.MOVE:
			var dist := to_player.length()
			if dist > data.keep_distance:
				velocity = to_player.normalized() * data.move_speed
			elif dist < data.keep_distance * 0.7:
				velocity = -to_player.normalized() * data.move_speed
			else:
				velocity = Vector2.ZERO
			_cooldown -= delta
			if _cooldown <= 0.0:
				_begin_attack(to_player)
		State.WINDUP:
			velocity = Vector2.ZERO
			_state_time -= delta
			if _state_time <= 0.0:
				_fire_attack()
		State.BURST:
			velocity = Vector2.ZERO  # серию ведёт PatternRunner, по её окончании придёт _on_attack_finished


func _begin_attack(to_player: Vector2) -> void:
	if data.attacks.is_empty():
		_cooldown = data.fire_interval
		return
	if data.attack_order == EnemyData.AttackOrder.RANDOM:
		_attack = data.attacks.pick_random()
	else:
		_attack = data.attacks[_attack_index % data.attacks.size()]
		_attack_index += 1
	_aim = to_player.normalized()
	if _attack.windup > 0.0:
		_state = State.WINDUP
		_state_time = _attack.windup
	else:
		_fire_attack()


func _fire_attack() -> void:
	_state = State.BURST
	_runner.start(_attack, _aim)


func _on_attack_finished() -> void:
	_state = State.MOVE
	_cooldown = data.fire_interval


# --- LUNGE ------------------------------------------------------------------

func _tick_lunge(delta: float, to_player: Vector2) -> void:
	match _state:
		State.MOVE:
			velocity = to_player.normalized() * data.move_speed
			_cooldown -= delta
			if _cooldown <= 0.0 and to_player.length() <= data.lunge_range:
				_aim = to_player.normalized()
				_state = State.WINDUP
				_state_time = data.lunge_windup
		State.WINDUP:
			velocity = Vector2.ZERO
			_state_time -= delta
			if _state_time <= 0.0:
				_state = State.LUNGING
				_state_time = data.lunge_duration
		State.LUNGING:
			velocity = _aim * data.lunge_speed
			_state_time -= delta
			if _state_time <= 0.0:
				_state = State.REST
				_state_time = data.lunge_rest
		State.REST:
			velocity = Vector2.ZERO
			_state_time -= delta
			if _state_time <= 0.0:
				_state = State.MOVE
				_cooldown = data.fire_interval


# --- Контакт, смерть --------------------------------------------------------

func _check_contact() -> void:
	if data.contact_damage <= 0 or _contact_cd > 0.0:
		return
	var player := _player as Player
	if player == null:
		return
	if global_position.distance_to(player.global_position) <= data.radius + player.hitbox_radius + 3.0:
		player.take_damage(data.contact_damage)
		_contact_cd = data.contact_interval


func _on_died() -> void:
	EventBus.enemy_killed.emit(self)
	if data.split_into != null and data.split_count > 0:
		for i in data.split_count:
			var child := Enemy.new()
			child.data = data.split_into
			child.position = global_position + Vector2.from_angle(TAU * float(i) / float(data.split_count)) * 12.0
			get_parent().add_child.call_deferred(child)
	queue_free()


# --- Отрисовка --------------------------------------------------------------

func _draw() -> void:
	if _state == State.WINDUP:
		_draw_telegraph()
	var tint := Color(2, 2, 2) if _flash > 0.0 else Color.WHITE
	if data.sprite != null:
		draw_texture(data.sprite, -data.sprite.get_size() / 2.0, tint)
	else:
		draw_circle(Vector2.ZERO, data.radius, data.color * tint)
	var frac := float(health.current) / float(health.max_health)
	var bar_y := -data.radius - 6.0
	draw_rect(Rect2(-10.0, bar_y, 20.0, 2.0), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(-10.0, bar_y, 20.0 * frac, 2.0), Color(0.9, 0.3, 0.3))


## Предупреждение: линия в сторону удара (прицельные атаки и рывок) или расходящееся кольцо.
## Тоньше и бледнее в начале, ярче к моменту атаки.
func _draw_telegraph() -> void:
	if data.behavior == EnemyData.Behavior.LUNGE:
		var progress := 1.0 - _state_time / maxf(data.lunge_windup, 0.01)
		var c := data.color
		var length := data.lunge_speed * data.lunge_duration
		draw_line(Vector2.ZERO, _aim * length, Color(c.r, c.g, c.b, 0.2 + 0.6 * progress), 1.0 + 2.0 * progress)
		return
	if _attack == null:
		return
	var windup_progress := 1.0 - _state_time / maxf(_attack.windup, 0.01)
	var color := Color(_attack.color.r, _attack.color.g, _attack.color.b, 0.2 + 0.6 * windup_progress)
	if _attack.aim == BulletPattern.Aim.FIXED:
		draw_arc(Vector2.ZERO, data.radius + 3.0 + 10.0 * windup_progress, 0.0, TAU, 24, color, 1.5)
	else:
		draw_line(Vector2.ZERO, _aim * 240.0, color, 1.0 + 2.0 * windup_progress)
