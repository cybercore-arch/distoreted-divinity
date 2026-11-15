class_name WeaponData
extends Resource
## Оружие: название, два режима (стрелки — primary, E — alt) и правила заряда альта.
## Альт мощный, но доступен только когда шкала заряда полная. Шкала копится от урона,
## который игрок наносит врагам.

enum Rarity { COMMON, UNCOMMON, RARE }

@export var display_name: String = "Оружие"
@export var icon: Texture2D  ## позже: предмет 64x64
@export var rarity: Rarity = Rarity.COMMON
@export var tags: PackedStringArray = []  ## теги для условий маршрутов, например "holy"
@export var primary: FireMode
@export var alt: FireMode
@export var alt_name: String = "Альт"
@export var alt_damage_needed: float = 200.0  ## сколько урона нужно нанести, чтобы зарядить альт
