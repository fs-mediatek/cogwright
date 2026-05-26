class_name Tower extends RefCounted

var name: String = "Tower"
var hp: int = 100
var max_hp: int = 100

var floors: Array[FloorConfig] = []
var slots: Array[ItemSlot] = []

func add_slot(item: Item, floor_idx: int, slot_idx: int) -> void:
	slots.append(ItemSlot.new(item, floor_idx, slot_idx))

func slots_on_floor(floor_idx: int) -> Array[ItemSlot]:
	var result: Array[ItemSlot] = []
	for s in slots:
		if s.floor_idx == floor_idx:
			result.append(s)
	return result

func is_alive() -> bool:
	return hp > 0

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
