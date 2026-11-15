class_name WeaponData
extends Resource
## Оружие: название и два режима огня (стрелки — primary, E — alt).

@export var display_name: String = "Оружие"
@export var icon: Texture2D  ## позже: предмет 64x64
@export var tags: PackedStringArray = []  ## теги для условий маршрутов, например "holy"
@export var primary: FireMode
@export var alt: FireMode
