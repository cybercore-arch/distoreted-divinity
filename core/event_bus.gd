extends Node
## Глобальная шина событий. Системы общаются сигналами, а не прямыми ссылками.

signal player_health_changed(current: int, maximum: int)
signal weapon_changed(weapon: WeaponData)
signal dash_cooldown_changed(remaining: float, total: float)
signal enemy_killed(enemy: Node)
