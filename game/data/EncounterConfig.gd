class_name EncounterConfig extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var base_hp: int = 200
@export var item_ids: Array[StringName] = []
# Parallel zu item_ids: floor_idx * 3 + slot_idx
@export var slot_indices: Array[int] = []

func build_tower() -> Tower:
	var t := Tower.new()
	t.name = display_name if display_name != "" else "Rival"
	t.floors = _load_floors()
	var hp_total: float = float(base_hp)
	for f in t.floors:
		hp_total += float(base_hp) * f.hp_modifier
	# Heat-Modifier: +12% HP pro Stufe
	var heat_mult: float = 1.0 + 0.12 * float(MetaState.selected_heat)
	hp_total *= heat_mult
	t.max_hp = int(round(hp_total))
	t.hp = t.max_hp
	for i in range(item_ids.size()):
		if i >= slot_indices.size():
			break
		var item: Item = load("res://data/items/%s.tres" % String(item_ids[i]))
		var slot_index: int = slot_indices[i]
		var floor_idx: int = slot_index / 3
		var slot_idx: int = slot_index % 3
		t.add_slot(item, floor_idx, slot_idx)
	return t

func _load_floors() -> Array[FloorConfig]:
	var f: Array[FloorConfig] = []
	f.append(load("res://data/floors/foundation.tres"))
	f.append(load("res://data/floors/workshop.tres"))
	f.append(load("res://data/floors/pinnacle.tres"))
	return f
