extends Node
## Реестр контента (автозагрузка ContentRegistry). Находит все .tres оружия, артефактов и врагов
## в data/ и отдаёт их по короткой ссылке:
##   w.1 — оружие №1, a.1 — артефакт №1, e.1 — враг №1 (номер = поле id в ресурсе);
##   w.holy_spear — то же по имени файла.
## Номера задаются вручную в .tres и не меняются, поэтому ссылки стабильны.
## Новый .tres в нужной папке попадает в реестр сам, без правок кода.

const KIND_DIRS := {
	"w": "res://data/weapons",
	"a": "res://data/artifacts",
	"e": "res://data/enemies",
	"p": "res://data/patterns",
}
const KIND_NAMES := {"w": "оружие", "a": "артефакты", "e": "враги", "p": "паттерны пуль"}
const KIND_ALIASES := {
	"w": "w", "weapon": "w", "a": "a", "artifact": "a", "e": "e", "enemy": "e", "p": "p", "pattern": "p",
}
const UNASSIGNED_ORDER: int = 1000000  ## ресурсы без номера идут в конец списка

var _entries: Dictionary = {"w": [], "a": [], "e": [], "p": []}  ## тип -> Array[Dictionary {id, stem, resource}]


func _ready() -> void:
	for kind in KIND_DIRS:
		_load_kind(kind)


## Список записей типа ("w", "a", "e"), отсортированный по номеру.
func entries(kind: String) -> Array:
	return _entries.get(kind, [])


func weapons() -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	for entry in _entries["w"]:
		result.append(entry["resource"] as WeaponData)
	return result


func artifacts() -> Array[ArtifactData]:
	var result: Array[ArtifactData] = []
	for entry in _entries["a"]:
		result.append(entry["resource"] as ArtifactData)
	return result


func enemies() -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	for entry in _entries["e"]:
		result.append(entry["resource"] as EnemyData)
	return result


## "weapon", "w", "W" -> "w"; неизвестное -> "".
func normalize_kind(text: String) -> String:
	return KIND_ALIASES.get(text.strip_edges().to_lower(), "")


## Разбирает ссылку вида "w.1" или "w.holy_spear".
## Возвращает {"kind": "w", "resource": Resource} или {"error": "текст ошибки"}.
func resolve(ref: String) -> Dictionary:
	var parts := ref.strip_edges().to_lower().split(".", true, 1)
	if parts.size() != 2 or parts[1] == "":
		return {"error": "ссылка должна быть вида w.1 или w.имя_файла, а не «%s»" % ref}
	var kind := normalize_kind(parts[0])
	if kind == "":
		return {"error": "неизвестный тип «%s» (w — оружие, a — артефакт, e — враг, p — паттерн)" % parts[0]}
	var key: String = parts[1]
	for entry in _entries[kind]:
		var id: int = entry["id"]
		if (key.is_valid_int() and id > 0 and int(key) == id) or key == (entry["stem"] as String).to_lower():
			return {"kind": kind, "resource": entry["resource"]}
	return {"error": "не найдено: %s (список: list %s)" % [ref, kind]}


func display_name_of(resource: Resource) -> String:
	return str(resource.get("display_name"))


func _load_kind(kind: String) -> void:
	var list: Array = _entries[kind]
	var seen_ids: Dictionary = {}
	for path in _resource_paths(KIND_DIRS[kind]):
		var resource := load(path)
		if resource == null or not _matches(kind, resource):
			continue
		var id: int = resource.get("id")
		if id > 0:
			if seen_ids.has(id):
				push_warning("Реестр: номер %s.%d уже занят (%s), повтор в %s" % [kind, id, seen_ids[id], path])
			seen_ids[id] = path
		list.append({"id": id, "stem": path.get_file().get_basename(), "resource": resource})
	list.sort_custom(_entry_before)


func _entry_before(a: Dictionary, b: Dictionary) -> bool:
	var order_a: int = a["id"] if a["id"] > 0 else UNASSIGNED_ORDER
	var order_b: int = b["id"] if b["id"] > 0 else UNASSIGNED_ORDER
	if order_a != order_b:
		return order_a < order_b
	return (a["stem"] as String) < (b["stem"] as String)


func _matches(kind: String, resource: Resource) -> bool:
	match kind:
		"w":
			return resource is WeaponData
		"a":
			return resource is ArtifactData
		"e":
			return resource is EnemyData
		"p":
			return resource is BulletPattern
	return false


## Пути всех .tres в папке по алфавиту (в экспортированной игре к ним добавляется .remap).
func _resource_paths(dir: String) -> PackedStringArray:
	var paths := PackedStringArray()
	for file_name in DirAccess.get_files_at(dir):
		var clean := file_name.trim_suffix(".remap")
		if clean.ends_with(".tres"):
			paths.append(dir.path_join(clean))
	paths.sort()
	return paths
