class_name WeaponPedestal
extends Pedestal
## Пьедестал с оружием.
## Есть свободный слот — оружие забирается в него, пьедестал пустеет.
## Слоты заняты — заменяется активное оружие, а прежнее остаётся на пьедестале:
## можно пробовать всё по очереди.

const RARITY_COLORS: Dictionary = {
	WeaponData.Rarity.COMMON: Color(0.85, 0.85, 0.9),
	WeaponData.Rarity.UNCOMMON: Color(0.5, 0.85, 0.7),
	WeaponData.Rarity.RARE: Color(1.0, 0.8, 0.25),
}

var weapon: WeaponData


func _has_item() -> bool:
	return weapon != null


func _take(player: Player) -> void:
	weapon = player.pick_up(weapon)  # прежнее оружие игрока (или null) остаётся на пьедестале


func _accent() -> Color:
	return RARITY_COLORS.get(weapon.rarity, Color.WHITE)


func _title() -> String:
	return weapon.display_name


func _details() -> String:
	return "Альт: " + weapon.alt_name


func _draw_icon() -> void:
	if weapon.icon != null:
		draw_texture_rect(weapon.icon, Rect2(-12.0, -12.0, 24.0, 24.0), false)
	else:
		var tint := weapon.primary.color if weapon.primary != null else Color.WHITE
		draw_colored_polygon(PackedVector2Array([Vector2(0, -7), Vector2(6, 0), Vector2(0, 7), Vector2(-6, 0)]), tint)
