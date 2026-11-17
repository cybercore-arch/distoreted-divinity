extends Node
## Глобальная шина событий. Системы общаются сигналами, а не прямыми ссылками.

signal player_health_changed(current: int, maximum: int)
signal loadout_changed(weapons: Array, active_slot: int, limit: int)  ## оружие игрока, активный слот, лимит слотов
signal artifacts_changed(artifacts: Array)
signal dash_cooldown_changed(remaining: float, total: float)
signal alt_charge_changed(fraction: float)
signal enemy_damaged(amount: int)
signal enemy_killed(enemy: Node)
signal room_changed(title: String)
