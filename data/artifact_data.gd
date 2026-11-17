class_name ArtifactData
extends Resource
## Артефакт: пассивный предмет. Эффекты — поля данных, которые читает игрок (код не трогаем).

@export var id: int = 0  ## номер для консоли: give a.N (задаётся вручную и не меняется)
@export var display_name: String = "Артефакт"
@export_multiline var description: String = ""
@export var icon: Texture2D  ## позже: предмет 64x64
@export var tags: PackedStringArray = []
@export var weapon_slots_bonus: int = 0  ## сколько дополнительных слотов оружия даёт
