class_name RoomData
extends Resource
## Описание комнаты. Содержимое — только данные, комната собирается из них (rooms/room.gd).

enum Kind { HUB, WEAPONS, ENEMIES, ARTIFACTS }

@export var kind: Kind = Kind.HUB
@export var title: String = ""
@export var weapons: Array[WeaponData] = []  ## WEAPONS: по пьедесталу на каждое оружие
@export var enemies: Array[EnemyData] = []  ## ENEMIES: кто появляется (тип можно повторять)
@export var artifacts: Array[ArtifactData] = []  ## ARTIFACTS: по пьедесталу на каждый артефакт
