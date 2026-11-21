class_name ArtifactPedestal
extends Pedestal
## Пьедестал с артефактом: коснулся — артефакт у игрока, пьедестал пустеет.
## Комната пересоздаётся при каждом входе, поэтому в тестовых комнатах артефакты можно брать
## повторно (проверка стаков); убрать их — консольная команда drop.

var artifact: ArtifactData


func _has_item() -> bool:
	return artifact != null


func _take(player: Player) -> void:
	player.add_artifact(artifact)
	artifact = null


func _accent() -> Color:
	return artifact.quality_color()


func _title() -> String:
	return "%s  (q%d)" % [artifact.display_name, artifact.quality]


func _details() -> String:
	return artifact.description


func _draw_icon() -> void:
	if artifact.icon != null:
		draw_texture_rect(artifact.icon, Rect2(-12.0, -12.0, 24.0, 24.0), false)
		return
	# Заглушка без спрайта: ромб цвета качества и столько точек, какое качество.
	var color := artifact.quality_color()
	draw_colored_polygon(PackedVector2Array([Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0)]), color)
	for i in artifact.quality:
		draw_circle(Vector2(-6.0 + 4.0 * float(i), HALF - 2.0), 1.0, Color(0.1, 0.1, 0.15))
