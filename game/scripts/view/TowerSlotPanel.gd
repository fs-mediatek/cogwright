class_name TowerSlotPanel extends PanelContainer

# Drop-Target für Drag-and-Drop von Items aus dem Inventar.
# Sendet item_dropped(inv_idx, slot_idx), wenn ein gültiges Item gedroppt wird.

signal item_dropped(inv_idx: int, slot_idx: int)

var slot_idx: int = -1
var accepts_drop: bool = true   # false wenn der Slot bereits belegt ist

func _can_drop_data(_at_position: Vector2, data) -> bool:
	if not (data is Dictionary):
		return false
	if String(data.get("type", "")) != "inventory_item":
		return false
	return accepts_drop

func _drop_data(_at_position: Vector2, data) -> void:
	if not (data is Dictionary):
		return
	var idx: int = int(data.get("inv_idx", -1))
	if idx < 0:
		return
	item_dropped.emit(idx, slot_idx)
