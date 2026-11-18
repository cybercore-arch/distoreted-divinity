class_name BulletPattern
extends Resource
## Паттерн пуль: одна атака врага или босса, целиком в данных. Выполняет её PatternRunner.
## Устроен в три уровня: пуля -> выстрел (несколько пуль веером или кольцом) -> серия выстрелов.

enum Aim {
	AT_PLAYER,  ## в сторону игрока, направление фиксируется в начале атаки
	TRACK_PLAYER,  ## каждый выстрел серии заново целится в игрока
	FIXED,  ## мировые углы, не зависит от игрока (кольца, спирали)
}

@export var id: int = 0  ## номер для консоли: fire p.N (задаётся вручную и не меняется)
@export var display_name: String = "Паттерн"
@export var windup: float = 0.0  ## предупреждение перед атакой, секунд (враг замирает, показывается линия)

@export_group("Направление")
@export var aim: Aim = Aim.AT_PLAYER
@export var angle_offset_degrees: float = 0.0  ## постоянный поворот всего паттерна

@export_group("Выстрел")
@export var bullets: int = 8  ## пуль за выстрел
@export var arc_degrees: float = 360.0  ## на какой угол раскинуты пули; 360 = кольцо, 20 = узкий веер
@export var jitter_degrees: float = 0.0  ## случайный разброс каждой пули (дробовик)

@export_group("Серия")
@export var shots: int = 1  ## выстрелов за атаку
@export var shot_interval: float = 0.1  ## пауза между выстрелами серии
@export var rotate_per_shot_degrees: float = 0.0  ## поворот после каждого выстрела серии (спираль)
@export var rotate_per_use_degrees: float = 0.0  ## поворот после каждой новой атаки (кольцо «провёрнуто» в следующий раз)

@export_group("Пуля")
@export var speed: float = 90.0
@export var acceleration: float = 0.0  ## изменение скорости в секунду (отрицательное — тормозит)
@export var turn_degrees_per_second: float = 0.0  ## изгиб траектории (пули летят дугой)
@export var lifetime: float = 4.0
@export var radius: float = 3.0
@export var damage: int = 10
@export var color: Color = Color(1.0, 0.35, 0.3)
